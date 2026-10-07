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
  }) async {
    return api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'companyName': companyName,
    }

    );
  
  }

  Future<User> me() async {
    final json = await api.get('/auth/me');
    return User.fromJson(json);
  }

}