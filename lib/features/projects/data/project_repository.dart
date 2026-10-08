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
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final data = await _api.post('/projects/create', body);
    return Project.fromJson(data);
  }

  Future<Project> updateProject(
    int id, {
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final data = await _api.put('/projects/update/$id', body);
    return Project.fromJson(data);
  }

  /// Soft delete on backend (isActive = false)
  Future<void> deleteProject(int id) async {
    await _api.delete('/projects/delete/$id');
  }
}