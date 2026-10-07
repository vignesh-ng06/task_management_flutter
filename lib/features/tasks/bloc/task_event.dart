import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  const TasksLoadRequested();
}

class TasksRefreshRequested extends TaskEvent {
  const TasksRefreshRequested();
}

class TaskStatusUpdateRequested extends TaskEvent {
  final int taskId;
  final String newStatus;
  const TaskStatusUpdateRequested(this.taskId, this.newStatus);

  @override
  List<Object?> get props => [taskId, newStatus];
}