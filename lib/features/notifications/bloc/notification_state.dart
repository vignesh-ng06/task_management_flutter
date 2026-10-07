import 'package:equatable/equatable.dart';
import '../data/models/notification.dart';

enum NotificationListStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationListStatus status;
  final List<AppNotification> items;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.status = NotificationListStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    NotificationListStatus? status,
    List<AppNotification>? items,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, items, unreadCount, error];
}