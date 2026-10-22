import '../../../core/api/api_client.dart';
import 'models/project.dart';

class ProjectRepository {
  final ApiClient _api;
  ProjectRepository(this._api);

  Future<List<Project>> listProjects({bool includeInactive = false}) async {
    final query = includeInactive ? '?includeInactive=true' : '';
    final data = await _api.get('/projects/getAll$query');
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(Project.fromJson).toList();
  }

  Future<Project> getProject(int id) async {
    final data = await _api.get('/projects/getById/$id');
    return Project.fromJson(data);
  }

  Future<Project> createProject({
    required String name,
    String? description,
    List<int>? memberIds,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    if (memberIds != null) {
      body['memberIds'] = memberIds;
    }
    final data = await _api.post('/projects/create', body);
    return Project.fromJson(data);
  }

  Future<Project> updateProject(
    int id, {
    String? name,
    String? description,
    List<int>? memberIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    if (memberIds != null) body['memberIds'] = memberIds;

    final data = await _api.put('/projects/update/$id', body);
    return Project.fromJson(data);
  }

  /// Soft delete on backend (isActive = false)
  Future<void> deleteProject(int id) async {
    await _api.delete('/projects/delete/$id');
  }

  /// PATCH /projects/activate/:id
  Future<void> activateProject(int id) async {
    await _api.patch('/projects/activate/$id', {});
  }

  //New methods for member management

  Future<Project> addMembers(int projectId, List<int> userIds) async {
    final data = await _api.post('/projects/$projectId/members', {
      'userIds': userIds,
    });
    return Project.fromJson(data);
  }

  Future<void> removeMember(int projectId, int userId) async {
    await _api.delete('/projects/$projectId/members/$userId');
  }
}
