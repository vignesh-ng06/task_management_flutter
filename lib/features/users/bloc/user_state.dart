import 'package:equatable/equatable.dart';

import '../../auth/data/user_model.dart';

enum UserListStatus { initial, loading, loaded, error }

class UserState extends Equatable {
  final UserListStatus status;
  final List<User> users;
  final String? error;
  final String? successMessage;
  final String roleFilter; // 'all' | 'admin' | 'manager' | 'employee'
  final bool includeInactive;

  const UserState({
    this.status = UserListStatus.initial,
    this.users = const [],
    this.error,
    this.successMessage,
    this.roleFilter = 'all',
    this.includeInactive = false,
  });

  UserState copyWith({
    UserListStatus? status,
    List<User>? users,
    String? error,
    String? successMessage,
    String? roleFilter,
    bool? includeInactive,
    bool clearMessages = false,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      error: clearMessages ? null : (error ?? this.error),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      roleFilter: roleFilter ?? this.roleFilter,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }

  List<User> get filteredUsers {
    if (roleFilter == 'all') return users;
    return users.where((u) => u.role == roleFilter).toList();
  }

  @override
  List<Object?> get props => [
    status,
    users,
    error,
    successMessage,
    roleFilter,
    includeInactive,
  ];
}
