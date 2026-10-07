import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {}

class NotificationsUnreadCountRequested extends NotificationEvent {}

class NotificationMarkReadRequested extends NotificationEvent {
  final int id;
  const NotificationMarkReadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllReadRequested extends NotificationEvent {}

class NotificationDeleteRequested extends NotificationEvent {
  final int id;
  const NotificationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}