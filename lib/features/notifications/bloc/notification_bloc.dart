import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repo;

  NotificationBloc(this._repo) : super(const NotificationState()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationsUnreadCountRequested>(_onCount);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationListStatus.loading, clearError: true));
    try {
      final items = await _repo.getAll();
      final unread = await _repo.getUnreadCount();
      emit(state.copyWith(
        status: NotificationListStatus.loaded,
        items: items,
        unreadCount: unread,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: NotificationListStatus.error, error: e.message));
    }
  }

  Future<void> _onCount(
    NotificationsUnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await _repo.getUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (_) {/* silent */}
  }

  Future<void> _onMarkRead(
    NotificationMarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repo.markAsRead(event.id);
      final updated = state.items
          .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
          .toList();
      final unread = updated.where((n) => !n.isRead).length;
      emit(state.copyWith(items: updated, unreadCount: unread));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repo.markAllAsRead();
      final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
      emit(state.copyWith(items: updated, unreadCount: 0));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> _onDelete(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repo.delete(event.id);
      final updated = state.items.where((n) => n.id != event.id).toList();
      final unread = updated.where((n) => !n.isRead).length;
      emit(state.copyWith(items: updated, unreadCount: unread));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}