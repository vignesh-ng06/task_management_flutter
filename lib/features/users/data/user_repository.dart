import '../../../core/api/api_client.dart';
import '../../auth/data/user_model.dart';
import 'user_details.dart';

class UserPage {
  final List<User> users;
  final int total;
  final int totalPages;

  const UserPage({
    required this.users,
    required this.total,
    required this.totalPages,
  });
}

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  Future<List<User>> listUsers({bool isActive = true}) async {
    final query = isActive ? '' : '?status=inactive';
    final response = await _api.get('/users/getAllUsers$query');
    final usersData = response is List ? response : response['data'] as List;
    return usersData
        .map((json) => User.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<UserPage> listUsersPage({
    required bool isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (!isActive) params['status'] = 'inactive';
    final query =
        '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final response = await _api.get('/users/getAllUsers$query');

    if (response is! Map) {
      throw const FormatException('Invalid users response');
    }

    final root = Map<String, dynamic>.from(response);
    final usersData = root['data'];
    final paginationData = root['pagination'];
    if (usersData is! List || paginationData is! Map) {
      throw const FormatException(
        'Users response must contain data and pagination',
      );
    }

    final pagination = Map<String, dynamic>.from(paginationData);
    final users = usersData
        .map((json) => User.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
    return UserPage(
      users: users,
      total: (pagination['total'] as num).toInt(),
      totalPages: (pagination['totalPages'] as num).toInt(),
    );
  }

  Future<UserDetails> getUserDetails(int id) async {
    final response = await _api.get('/users/getUser/$id');
    if (response is! Map) {
      throw const FormatException('Invalid user details response');
    }

    final responseMap = Map<String, dynamic>.from(response);
    final data = responseMap['data'];
    if (data is! Map) {
      throw const FormatException('User details response is missing data');
    }

    return UserDetails.fromJson(Map<String, dynamic>.from(data));
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

  Future<void> updateUser(
    int id, {
    String? name,
    String? role,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (role != null) body['role'] = role;
    if (password != null && password.isNotEmpty) body['password'] = password;

    await _api.put('/users/updateUser/$id', body);
  }

  /// Soft delete — sets isActive = false on backend
  Future<void> deactivateUser(int id) async {
    await _api.delete('/users/deleteUser/$id');
  }

  /// PATCH /users/activateUser/:id
  Future<void> activateUser(int id) async {
    await _api.patch('/users/activateUser/$id', {});
  }
}
