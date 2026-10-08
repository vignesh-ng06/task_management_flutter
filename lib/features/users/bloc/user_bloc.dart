import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../data/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';
import '../../auth/data/user_model.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _repo;

  UserBloc(this._repo) : super(const UserState()) {
    on<UsersLoadRequested>(_onLoad);
    on<UserCreateRequested>(_onCreate);
    on<UserUpdateRequested>(_onUpdate);
    on<UserDeactivateRequested>(_onDeactivate);
    on<UserFilterChanged>((event, emit) {
      emit(state.copyWith(roleFilter: event.role));
    });
  }

  Future<void> _onLoad(
    UsersLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    final changingList = event.includeInactive != state.includeInactive;
    emit(
      state.copyWith(
        status: UserListStatus.loading,
        includeInactive: event.includeInactive,
        users: changingList ? [] : null,
        clearMessages: true,
      ),
    );
    try {
      final users = await _repo.listUsers(
        includeInactive: event.includeInactive,
      );
      emit(state.copyWith(status: UserListStatus.loaded, users: users));
    } on ApiException catch (e) {
      emit(state.copyWith(status: UserListStatus.error, error: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: UserListStatus.error,
          error: 'Failed to load users',
        ),
      );
    }
  }

  Future<void> _onCreate(
    UserCreateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(clearMessages: true));
    try {
      final user = await _repo.createUser(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      emit(
        state.copyWith(
          users: state.includeInactive ? state.users : [user, ...state.users],
          successMessage: 'User created successfully',
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

Future<void> _onUpdate(
  UserUpdateRequested event,
  Emitter<UserState> emit,
) async {
  emit(state.copyWith(clearMessages: true));

  final index = state.users.indexWhere((u) => u.id == event.id);
  if (index == -1) return;
  final original = state.users[index];

  // 1. Optimistic update — UI reflects instantly
  final optimistic = User(
    id: original.id,
    email: original.email,
    name: event.name ?? original.name,
    role: event.role ?? original.role,
    companyId: original.companyId,
    isActive: original.isActive,
    createdAt: original.createdAt,
  );
  final optimisticList = [...state.users]..[index] = optimistic;
  emit(state.copyWith(users: optimisticList));

  // 2. Backend call
  try {
    final serverUser = await _repo.updateUser(
      event.id,
      name: event.name,
      role: event.role,
      password: event.password,
    );

    // 3. Merge server response with any fields it didn't return
    final merged = User(
      id: serverUser.id,
      email: serverUser.email.isNotEmpty ? serverUser.email : original.email,
      name: serverUser.name ?? event.name ?? original.name,
      role: serverUser.role,
      companyId: serverUser.companyId != 0
          ? serverUser.companyId
          : original.companyId,
      isActive: serverUser.isActive,
      createdAt: serverUser.createdAt ?? original.createdAt,
    );

    final confirmed = [...state.users]..[index] = merged;
    emit(state.copyWith(
      users: confirmed,
      successMessage: 'User updated',
    ));
  } on ApiException catch (e) {
    // 4. Rollback on failure
    final rolledBack = [...state.users]..[index] = original;
    emit(state.copyWith(
      users: rolledBack,
      error: e.message,
    ));
  }
}

  Future<void> _onDeactivate(
    UserDeactivateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(clearMessages: true));
    try {
      await _repo.deactivateUser(event.id);
      emit(
        state.copyWith(
          users: state.includeInactive
              ? state.users
                    .map(
                      (u) => u.id == event.id
                          ? User(
                              id: u.id,
                              email: u.email,
                              name: u.name,
                              role: u.role,
                              companyId: u.companyId,
                              isActive: false,
                              createdAt: u.createdAt,
                            )
                          : u,
                    )
                    .toList()
              : state.users.where((u) => u.id != event.id).toList(),
          successMessage: 'User deactivated',
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}
