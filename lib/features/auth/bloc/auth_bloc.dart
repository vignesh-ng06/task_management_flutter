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
  }) : _repo = repo,
       _api = api,
       _storage = storage,
       super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdateRequested>(_onProfileUpdate);
    on<AuthCompanyUpdateRequested>(_onCompanyUpdate);
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
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final data = await _repo.login(event.email, event.password);
      final token = data['token'] as String;
      final user = _userFromAuthResponse(data);

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
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final data = await _repo.register(
        email: event.email,
        password: event.password,
        name: event.name,
        companyName: event.companyName,
        industry: event.industry,
        website: event.website,
        companySize: event.companySize,
      );

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        emit(
          const AuthState.unauthenticated(
            successMessage: 'Registration successful. Please log in.',
          ),
        );
        return;
      }

      final user = _userFromAuthResponse(data);

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

  Future<void> _onProfileUpdate(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final response = await _repo.updateMe(
        name: event.name,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final userResponse = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      final updated = User.fromJson({
        ...currentUser.toJson(),
        'companyName': currentUser.companyName,
        'industry': currentUser.industry,
        ...userResponse,
      });
      emit(
        state.copyWith(
          user: updated,
          isLoading: false,
          clearError: true,
          successMessage: 'Profile updated',
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Failed to update profile'));
    }
  }

  Future<void> _onCompanyUpdate(
    AuthCompanyUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null || currentUser.role != 'admin') return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final response = await _repo.updateCompany(
        name: event.name,
        industry: event.industry,
        website: event.website,
        companySize: event.companySize,
      );
      final companyResponse = response['company'];
      final company = <String, dynamic>{
        'name': event.name,
        'industry': event.industry,
        'website': event.website,
        'companySize': event.companySize,
        if (companyResponse is Map<String, dynamic>) ...companyResponse,
        if (companyResponse is! Map<String, dynamic>) ...response,
      };
      if (response['companyName'] is String) {
        company['name'] = response['companyName'];
      }

      final updated = User.fromJson({
        ...currentUser.toJson(),
        'company': company,
      });
      emit(
        state.copyWith(
          user: updated,
          isLoading: false,
          clearError: true,
          successMessage: 'Company updated',
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Failed to update company'));
    }
  }

  User _userFromAuthResponse(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    final company = data['company'];
    return User.fromJson({
      ...user,
      if (company is Map<String, dynamic>) 'company': company,
    });
  }
}
