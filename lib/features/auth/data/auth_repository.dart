import 'package:task_app/core/api/api_client.dart';

import 'user_model.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    return api.post('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? industry,
    String? website,
    String? companySize,
  }) async {
    return api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'companyName': companyName,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (website != null && website.isNotEmpty) 'website': website,
      if (companySize != null && companySize.isNotEmpty)
        'companySize': companySize,
    });
  }

  Future<User> me() async {
    final json = await api.get('/auth/me');
    return User.fromJson(json);
  }

  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (newPassword != null && newPassword.isNotEmpty) {
      body['newPassword'] = newPassword;
      body['currentPassword'] = currentPassword;
    }

    return api.patch('/auth/update/me', body);
  }

  Future<Map<String, dynamic>> updateCompany({
    required String name,
    required String industry,
    required String website,
    required String companySize,
  }) {
    return api.patch('/auth/update/company', {
      'name': name,
      'industry': industry,
      'website': website,
      'companySize': companySize,
    });
  }
}
