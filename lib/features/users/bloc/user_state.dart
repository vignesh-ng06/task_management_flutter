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
  final int? total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const UserState({
    this.status = UserListStatus.initial,
    this.users = const [],
    this.error,
    this.successMessage,
    this.roleFilter = 'all',
    this.includeInactive = false,
    this.searchQuery = '',
    this.total,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  UserState copyWith({
    UserListStatus? status,
    List<User>? users,
    String? error,
    String? successMessage,
    String? roleFilter,
    bool? includeInactive,
    String? searchQuery,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearMessages = false,
    bool clearTotal = false,
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
      total: clearTotal ? null : (total ?? this.total),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  List<User> get filteredUsers {
    Iterable<User> list = users;

    if (roleFilter != 'all') {
      list = list.where((u) => u.role == roleFilter);
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where(
        (u) =>
            (u.name?.toLowerCase().contains(q) ?? false) ||
            u.email.toLowerCase().contains(q),
      );
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
    total,
    page,
    hasMore,
    isLoadingMore,
  ];
}
