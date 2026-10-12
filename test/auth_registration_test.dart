import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/core/storage/token_storage.dart';
import 'package:task_app/features/auth/bloc/auth_bloc.dart';
import 'package:task_app/features/auth/bloc/auth_event.dart';
import 'package:task_app/features/auth/bloc/auth_state.dart';
import 'package:task_app/features/auth/data/auth_repository.dart';

class _SuccessfulRegistrationRepository extends AuthRepository {
  _SuccessfulRegistrationRepository() : super(ApiClient());

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? industry,
    String? website,
  }) async {
    return {
      'user': {
        'id': 12,
        'email': email,
        'name': name,
        'role': 'admin',
        'companyId': 3,
      },
      'company': {'id': 3, 'name': companyName},
    };
  }
}

void main() {
  test(
    'successful registration without a token prompts the user to log in',
    () async {
      final bloc = AuthBloc(
        repo: _SuccessfulRegistrationRepository(),
        api: ApiClient(),
        storage: TokenStorage(),
      );
      final completedState = bloc.stream.firstWhere(
        (state) => state.successMessage != null,
      );

      bloc.add(
        const AuthRegisterSubmitted(
          email: 'jeeva@gmail.com',
          password: 'password123',
          name: 'jeeva',
          companyName: 'RPS Tech park',
        ),
      );

      final state = await completedState;

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isNull);
      expect(state.successMessage, 'Registration successful. Please log in.');

      await bloc.close();
    },
  );
}
