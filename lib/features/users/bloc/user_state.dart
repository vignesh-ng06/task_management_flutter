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
  final String searchQuery;

  const UserState({
    this.status = UserListStatus.initial,
    this.users = const [],
    this.error,
    this.successMessage,
    this.roleFilter = 'all',
    this.includeInactive = false,
    this.searchQuery = '',
  });

  UserState copyWith({
    UserListStatus? status,
    List<User>? users,
    String? error,
    String? successMessage,
    String? roleFilter,
    bool? includeInactive,
    String? searchQuery,
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
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<User> get filteredUsers {
    Iterable<User> list = users;

    if (roleFilter != 'all') {
      list = list.where((u) => u.role == roleFilter);
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((u) =>
          (u.name?.toLowerCase().contains(q) ?? false) ||
          u.email.toLowerCase().contains(q));
    }

    return list.toList();
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
