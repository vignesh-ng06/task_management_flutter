import '../../../core/api/api_client.dart';
import 'models/task_model.dart';
import 'models/comment.dart';
import '../bloc/task_state.dart';

class TaskPage {
  final List<Task> tasks;
  final int? total;

  const TaskPage({required this.tasks, this.total});
}

class TaskRepository {
  final ApiClient _api;
  TaskRepository(this._api);

  /// GET /tasks/me
  Future<List<Task>> getMyTasks({
    TaskFilters? filters,
    int? page,
    int? limit,
  }) async {
    final result = await getMyTasksPage(
      filters: filters,
      page: page ?? 1,
      limit: limit ?? 20,
    );
    return result.tasks;
  }

  Future<TaskPage> getMyTasksPage({
    TaskFilters? filters,
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{};
    if (filters != null) {
      if (filters.status != null) q['status'] = filters.status!;
      if (filters.priority != null) q['priority'] = filters.priority!;
      if (filters.projectId != null) q['projectId'] = '${filters.projectId}';
      if (filters.search.isNotEmpty) q['search'] = filters.search;
      if (filters.includeInactive) q['includeInactive'] = 'true';
      // Note: assignedTo is intentionally ignored — /tasks/me is always "me"
    }
    q['page'] = '$page';
    q['limit'] = '$limit';

    final query = q.isEmpty
        ? ''
        : '?${q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    return _parsePage(await _api.get('/tasks/me$query'));
  }

  /// GET /tasks/:id
  Future<Task> getTask(int id) async {
    final data = await _api.get('/tasks/$id');
    final taskData = _taskPayload(data);
    if (taskData == null) {
      throw const FormatException(
        'The server response did not include valid task details.',
      );
    }
    return Task.fromJson(taskData);
  }

  /// PATCH /tasks/:id/status
  Future<Task> updateStatus(int id, String status) async {
    final data = await _api.patch('/tasks/updateTaskStatus/$id/status', {
      'status': status,
    });
    return Task.fromJson(data);
  }

  /// GET /comments/get/:taskId
  Future<List<Comment>> getComments(int taskId) async {
    final data = await _api.get('/comments/get/$taskId');
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(Comment.fromJson).toList();
  }

  /// POST /comments/create/:taskId
  Future<Comment> addComment(int taskId, String message) async {
    final data = await _api.post('/comments/create/$taskId', {
      'message': message,
    });
    return Comment.fromJson(data);
  }

  /// POST /tasks
  Future<Task?> createTask({
    required String title,
    String? description,
    required int projectId,
    int? assignedTo,
    required String priority, // 'HIGH' | 'MEDIUM' | 'LOW'
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'projectId': projectId,
      'priority': priority,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (assignedTo != null) body['assignedTo'] = assignedTo;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final data = await _api.post('/tasks/create', body);
    final taskData = _taskPayload(data);
    if (taskData != null) return Task.fromJson(taskData);
    return null;
  }

  /// PUT /tasks/:id
  Future<Task> updateTask(
    int id, {
    String? title,
    String? description,
    bool clearDescription = false,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? assignedTo,
    bool clearAssignee = false,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (clearDescription) {
      body['description'] = null;
    } else if (description != null) {
      body['description'] = description;
    }
    if (priority != null) body['priority'] = priority;
    if (clearDueDate) {
      body['dueDate'] = null;
    } else if (dueDate != null) {
      body['dueDate'] = dueDate.toIso8601String();
    }
    if (clearAssignee) {
      body['assignedTo'] = null;
    } else if (assignedTo != null) {
      body['assignedTo'] = assignedTo;
    }

    final data = await _api.put('/tasks/update/$id', body);
    final taskData = _taskPayload(data);
    if (taskData != null) return Task.fromJson(taskData);

    return getTask(id);
  }

  Map<String, dynamic>? _taskPayload(dynamic response) {
    if (response is! Map<String, dynamic>) return null;

    final nestedTask = response['task'];
    if (nestedTask is Map<String, dynamic>) return _taskPayload(nestedTask);

    final nestedData = response['data'];
    if (nestedData is Map<String, dynamic>) return _taskPayload(nestedData);

    final id = response['id'];
    final createdBy = response['createdBy'];
    final title = response['title'];
    final status = response['status'];
    final priority = response['priority'];
    final createdAt = response['createdAt'];
    final updatedAt = response['updatedAt'];

    if (id is! int ||
        createdBy is! int ||
        title is! String ||
        status is! String ||
        priority is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      return null;
    }
    return response;
  }

  /// DELETE /tasks/:id (soft)
  Future<void> deleteTask(int id) async {
    await _api.delete('/tasks/delete/$id');
  }

  /// PATCH /tasks/activate/:id
  Future<void> activateTask(int id) async {
    await _api.patch('/tasks/activate/$id', {});
  }

  Future<List<Task>> listTasks({
    TaskFilters? filters,
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await listTasksPage(
      filters: filters,
      includeInactive: includeInactive,
      page: page,
      limit: limit,
    );
    return result.tasks;
  }

  Future<TaskPage> listTasksPage({
    TaskFilters? filters,
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{};
    if (includeInactive || (filters?.includeInactive ?? false)) {
      q['includeInactive'] = 'true';
    }
    q['page'] = '$page';
    q['limit'] = '$limit';
    if (filters != null) {
      if (filters.status != null) q['status'] = filters.status!;
      if (filters.priority != null) q['priority'] = filters.priority!;
      if (filters.projectId != null) q['projectId'] = '${filters.projectId}';
      if (filters.assignedTo != null) q['assignedTo'] = '${filters.assignedTo}';
      if (filters.search.isNotEmpty) q['search'] = filters.search;
    }

    final query = q.isEmpty
        ? ''
        : '?${q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    return _parsePage(await _api.get('/tasks/getAllTasks$query'));
  }

  TaskPage _parsePage(dynamic response) {
    if (response is! Map) {
      throw const FormatException('Invalid paginated tasks response');
    }

    final root = Map<String, dynamic>.from(response);
    dynamic payload = root['data'];
    int? total = _readInt(root['total']) ?? _readInt(root['count']);

    if (payload is Map) {
      final payloadMap = Map<String, dynamic>.from(payload);
      total ??= _readInt(payloadMap['total']) ?? _readInt(payloadMap['count']);
      total ??= _readNestedTotal(payloadMap['pagination']);
      total ??= _readNestedTotal(payloadMap['meta']);
      payload =
          payloadMap['items'] ?? payloadMap['tasks'] ?? payloadMap['data'];
    }

    total ??= _readNestedTotal(root['pagination']);
    total ??= _readNestedTotal(root['meta']);

    final list = (payload is List ? payload : const [])
        .cast<Map<String, dynamic>>();
    return TaskPage(tasks: list.map(Task.fromJson).toList(), total: total);
  }

  int? _readNestedTotal(dynamic value) {
    if (value is Map) return _readInt(value['total']);
    return null;
  }

  int? _readInt(dynamic value) => value is num ? value.toInt() : null;

  Future<Comment> updateComment(int commentId, String message) async {
    final data = await _api.put('/comments/update/$commentId', {
      'message': message,
    });
    return Comment.fromJson(data);
  }

  Future<void> deleteComment(int commentId) async {
    await _api.delete('/comments/delete/$commentId');
  }
}
