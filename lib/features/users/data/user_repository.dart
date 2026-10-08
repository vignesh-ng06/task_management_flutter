import '../../../core/api/api_client.dart';
import '../../auth/data/user_model.dart';

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  Future<List<User>> listUsers({bool includeInactive = false}) async {
    final query = includeInactive ? '?status=inactive' : '';
    final response = await _api.get('/users/getAllUsers$query');
    final usersData = response is List ? response : response['data'] as List;
    return usersData
        .map((json) => User.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final data = await _api.post('/users/createUser', {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
    return User.fromJson(data);
  }

  Future<User> updateUser(
    int id, {
    String? name,
    String? role,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (role != null) body['role'] = role;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final data = await _api.put('/users/updateUser/$id', body);
    return User.fromJson(data);
  }

  /// Soft delete — sets isActive = false on backend
  Future<void> deactivateUser(int id) async {
    await _api.delete('/users/deleteUser/$id');
  }
}
