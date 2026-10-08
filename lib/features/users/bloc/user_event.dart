import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class UsersLoadRequested extends UserEvent {
  final bool includeInactive;
  const UsersLoadRequested({this.includeInactive = false});
  @override
  List<Object?> get props => [includeInactive];
}

class UserCreateRequested extends UserEvent {
  final String email;
  final String password;
  final String name;
  final String role;

  const UserCreateRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, name, role];
}

class UserUpdateRequested extends UserEvent {
  final int id;
  final String? name;
  final String? role;
  final String? password;

  const UserUpdateRequested({
    required this.id,
    this.name,
    this.role,
    this.password,
  });

  @override
  List<Object?> get props => [id, name, role, password];
}

class UserDeactivateRequested extends UserEvent {
  final int id;
  const UserDeactivateRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class UserFilterChanged extends UserEvent {
  final String role;
  const UserFilterChanged(this.role);
  @override
  List<Object?> get props => [role];
}
