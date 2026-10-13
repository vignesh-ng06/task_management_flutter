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
  final String? industry;
  final String? website;
  final String? companySize;

  const AuthRegisterSubmitted({
    required this.email,
    required this.password,
    required this.name,
    required this.companyName,
    this.industry,
    this.website,
    this.companySize,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    name,
    companyName,
    industry,
    website,
    companySize,
  ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? name;
  final String? currentPassword;
  final String? newPassword;

  const AuthProfileUpdateRequested({
    this.name,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [name, currentPassword, newPassword];
}

class AuthCompanyUpdateRequested extends AuthEvent {
  final String name;
  final String industry;
  final String website;
  final String companySize;

  const AuthCompanyUpdateRequested({
    required this.name,
    required this.industry,
    required this.website,
    required this.companySize,
  });

  @override
  List<Object?> get props => [name, industry, website, companySize];
}
