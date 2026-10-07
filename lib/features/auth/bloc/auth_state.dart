import 'package:equatable/equatable.dart';
import '../data/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  const AuthState.unknown() : this();
  const AuthState.unauthenticated({String? error})
      : this(status: AuthStatus.unauthenticated, error: error);
  const AuthState.authenticated(User user)
      : this(status: AuthStatus.authenticated, user: user);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, error];
}