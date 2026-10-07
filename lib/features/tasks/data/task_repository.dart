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

}