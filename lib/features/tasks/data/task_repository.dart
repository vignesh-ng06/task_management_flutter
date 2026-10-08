import 'dart:math';

import '../../../core/api/api_client.dart';
import 'models/task_model.dart';
import 'models/comment.dart';

class TaskRepository {
  final ApiClient _api;
  TaskRepository(this._api);

  /// GET /tasks/me
  Future<List<Task>> getMyTasks() async {
    final data = await _api.get('/tasks/me');
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(Task.fromJson).toList();
  }

  /// GET /tasks/:id
  Future<Task> getTask(int id) async {
    final data = await _api.get('/tasks/$id');
    print('TaskRepository.getTask: $data'); // Debugging line
    return Task.fromJson(data);
  }

  /// PATCH /tasks/:id/status
  Future<Task> updateStatus(int id, String status) async {
    final data = await _api.patch('/tasks/updateTaskStatus/$id/status', {'status': status});
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
Future<Task> createTask({
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
  return Task.fromJson(data);
}

/// PUT /tasks/:id
Future<Task> updateTask(
  int id, {
  String? title,
  String? description,
  String? priority,
  DateTime? dueDate,
  bool clearDueDate = false,
  int? assignedTo,
  bool clearAssignee = false,
}) async {
  final body = <String, dynamic>{};
  if (title != null) body['title'] = title;
  if (description != null) body['description'] = description;
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
  return Task.fromJson(data);
}

/// DELETE /tasks/:id (soft)
Future<void> deleteTask(int id) async {
  await _api.delete('/tasks/delete/$id');
}

}