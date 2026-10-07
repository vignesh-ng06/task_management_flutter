import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../data/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  final ApiClient _api;
  final TokenStorage _storage;

  AuthBloc({
    required AuthRepository repo,
    required ApiClient api,
    required TokenStorage storage,
  })  : _repo = repo,
        _api = api,
        _storage = storage,
        super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final token = await _storage.getToken();

    if (token == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    _api.setToken(token);
    try {
      final user = await _repo.me();
      emit(AuthState.authenticated(user));
    } catch (_) {
      await _storage.clear();
      _api.setToken(null);
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final data = await _repo.login(event.email, event.password);
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _storage.saveToken(token);
      _api.setToken(token);

      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      emit(AuthState.unauthenticated(error: e.message));
    } catch (e) {
      emit(AuthState.unauthenticated(error: 'Unexpected error'));
    }
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final data = await _repo.register(
        email: event.email,
        password: event.password,
        name: event.name,
        companyName: event.companyName,
      );
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _storage.saveToken(token);
      _api.setToken(token);

      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      emit(AuthState.unauthenticated(error: e.message));
    } catch (e) {
      emit(AuthState.unauthenticated(error: 'Unexpected error'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _storage.clear();
    _api.setToken(null);
    emit(const AuthState.unauthenticated());
  }
}