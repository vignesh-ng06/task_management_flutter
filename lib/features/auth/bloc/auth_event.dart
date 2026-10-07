import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String companyName;

  const AuthRegisterSubmitted({
    required this.email,
    required this.password,
    required this.name,
    required this.companyName,
  });

  @override
  List<Object?> get props => [email, password, name, companyName];
}

class AuthLogoutRequested extends AuthEvent {}