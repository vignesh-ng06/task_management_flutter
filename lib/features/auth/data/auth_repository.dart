import 'package:task_app/core/api/api_client.dart';

import 'user_model.dart';

class AuthRepository {
   final ApiClient api;
   AuthRepository(this.api);

   Future<Map<String, dynamic>>  login(String email, String password) async {
     return api.post('/auth/login',{
       'email': email,
       'password': password
     });
     
   }

Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? industry,
    String? website,
  }) async {
    return api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'companyName': companyName,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (website != null && website.isNotEmpty) 'website': website,
    });
  }

  Future<User> me() async {
    final json = await api.get('/auth/me');
    return User.fromJson(json);
  }

  Future<User> updateMe({
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

  final data = await api.patch('/auth/update/me', body);
  return User.fromJson(data);
}

}