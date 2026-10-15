import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/features/tasks/bloc/task_detail_bloc.dart';
import 'package:task_app/features/tasks/bloc/task_detail_event.dart';
import 'package:task_app/features/tasks/bloc/task_detail_state.dart';
import 'package:task_app/features/tasks/data/models/comment.dart';
import 'package:task_app/features/tasks/data/models/task_model.dart';
import 'package:task_app/features/tasks/data/task_repository.dart';

class _UpdateResponseClient extends http.BaseClient {
  String? updateBody;
  bool fetchedTask = false;

  final _updatedTask = {
    'id': 7,
    'title': 'Updated report',
    'description': null,
    'status': 'TODO',
    'priority': 'HIGH',
    'priorityLevel': 1,
    'dueDate': null,
    'assignedTo': null,
    'createdBy': 1,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-02T00:00:00.000Z',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'PUT') {
      updateBody = (request as http.Request).body;
      return _jsonResponse({'message': 'Task updated'});
    }
    if (request.method == 'GET') {
      fetchedTask = true;
      return _jsonResponse(_updatedTask);
    }
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }

  http.StreamedResponse _jsonResponse(Map<String, dynamic> body) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
    );
  }
}

class _CreateResponseClient extends http.BaseClient {
  final Map<String, dynamic> createResponse;
  String? createBody;
  bool fetchedCreatedTask = false;

  _CreateResponseClient(this.createResponse);

  final createdTask = {
    'id': 18,
    'title': 'Created task',
    'description': null,
    'status': 'TODO',
    'priority': 'LOW',
    'priorityLevel': 3,
    'dueDate': null,
    'assignedTo': null,
    'createdBy': 1,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST') {
      createBody = (request as http.Request).body;
      return _jsonResponse(createResponse);
    }
    if (request.method == 'GET' && request.url.path.endsWith('/tasks/18')) {
      fetchedCreatedTask = true;
      return _jsonResponse(createdTask);
    }
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }

  http.StreamedResponse _jsonResponse(Map<String, dynamic> body) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
    );
  }
}

class _FakeTaskRepository extends TaskRepository {
  _FakeTaskRepository() : super(ApiClient());

  final task = Task(
    id: 7,
    title: 'Prepare report',
    description: 'Draft the quarterly report',
    status: 'TODO',
    priority: 'MEDIUM',
    priorityLevel: 2,
    createdBy: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  String? updatedPriority;
  bool clearedDescription = false;
  Object? updateFailure;

  @override
  Future<Task> getTask(int id) async => task;

  @override
  Future<List<Comment>> getComments(int taskId) async => const [];

  @override
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
    updatedPriority = priority;
    clearedDescription = clearDescription;
    if (updateFailure case final failure?) throw failure;

    return task.copyWith(
      title: title,
      description: description,
      clearDescription: clearDescription,
      priority: priority,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
      assignedTo: assignedTo,
      clearAssignee: clearAssignee,
    );
  }
}

Future<void> _loadTask(TaskDetailBloc bloc, int taskId) async {
  final loaded = bloc.stream.firstWhere(
    (state) => state.status == TaskDetailStatus.loaded && state.task != null,
  );
  bloc.add(TaskDetailLoadRequested(taskId));
  await loaded;
}

void main() {
  test('repository parses a wrapped task creation response', () async {
    final client = _CreateResponseClient({
      'data': {
        'task': {
          'id': 18,
          'title': 'Created task',
          'description': null,
          'status': 'TODO',
          'priority': 'LOW',
          'priorityLevel': 3,
          'dueDate': null,
          'assignedTo': null,
          'createdBy': 1,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        },
      },
    });
    final repository = TaskRepository(ApiClient(client: client));

    final task = await repository.createTask(
      title: 'Created task',
      projectId: 2,
      priority: 'LOW',
    );

    expect(task?.id, 18);
    expect(task?.title, 'Created task');
    expect(task?.assignedTo, isNull);
    expect(client.fetchedCreatedTask, isFalse);
    final request = jsonDecode(client.createBody!) as Map<String, dynamic>;
    expect(request['projectId'], 2);
    expect(request['priority'], 'LOW');
  });

  test(
    'repository accepts successful create response without task details',
    () async {
      final client = _CreateResponseClient({
        'success': true,
        'data': {'taskId': 18},
      });
      final repository = TaskRepository(ApiClient(client: client));

      final task = await repository.createTask(
        title: 'Created task',
        projectId: 2,
        priority: 'LOW',
      );

      expect(task, isNull);
      expect(client.fetchedCreatedTask, isFalse);
    },
  );

  test(
    'repository reloads when create response has null integer fields',
    () async {
      final client = _CreateResponseClient({
        'task': {
          'id': 18,
          'title': 'Created task',
          'description': null,
          'status': 'TODO',
          'priority': 'LOW',
          'priorityLevel': null,
          'dueDate': null,
          'assignedTo': null,
          'createdBy': null,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        },
      });
      final repository = TaskRepository(ApiClient(client: client));

      final task = await repository.createTask(
        title: 'Created task',
        projectId: 2,
        priority: 'LOW',
      );

      expect(task, isNull);
      expect(client.fetchedCreatedTask, isFalse);
    },
  );

  test('repository refreshes task when update response has no task', () async {
    final client = _UpdateResponseClient();
    final repository = TaskRepository(ApiClient(client: client));

    final updated = await repository.updateTask(
      7,
      title: 'Updated report',
      clearDescription: true,
      priority: 'HIGH',
    );

    final requestBody = jsonDecode(client.updateBody!) as Map<String, dynamic>;
    expect(requestBody['title'], 'Updated report');
    expect(requestBody['description'], isNull);
    expect(requestBody['priority'], 'HIGH');
    expect(client.fetchedTask, isTrue);
    expect(updated.title, 'Updated report');
    expect(updated.priority, 'HIGH');
  });

  test('task detail update passes priority and description clearing', () async {
    final repository = _FakeTaskRepository();
    final bloc = TaskDetailBloc(repository);
    await _loadTask(bloc, repository.task.id);

    final updated = bloc.stream.firstWhere(
      (state) =>
          state.status == TaskDetailStatus.loaded &&
          state.task?.priority == 'HIGH',
    );
    bloc.add(
      TaskDetailUpdateRequested(
        taskId: repository.task.id,
        clearDescription: true,
        priority: 'HIGH',
      ),
    );

    final state = await updated;
    expect(repository.updatedPriority, 'HIGH');
    expect(repository.clearedDescription, isTrue);
    expect(state.task?.priority, 'HIGH');
    expect(state.task?.description, isNull);

    await bloc.close();
  });

  test('task detail update reports unexpected failures', () async {
    final repository = _FakeTaskRepository()
      ..updateFailure = const FormatException('unexpected response');
    final bloc = TaskDetailBloc(repository);
    await _loadTask(bloc, repository.task.id);

    final failed = bloc.stream.firstWhere(
      (state) => state.status == TaskDetailStatus.loaded && state.error != null,
    );
    bloc.add(
      TaskDetailUpdateRequested(
        taskId: repository.task.id,
        title: 'Updated report',
      ),
    );

    final state = await failed;
    expect(state.error, contains('unexpected response'));
    expect(state.task?.title, repository.task.title);

    await bloc.close();
  });
}
