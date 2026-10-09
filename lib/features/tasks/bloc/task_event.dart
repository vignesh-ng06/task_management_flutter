import 'package:equatable/equatable.dart';
import 'task_state.dart';

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

class TaskCreateRequested extends TaskEvent {
  final String title;
  final String? description;
  final int projectId;
  final int? assignedTo;
  final String priority;
  final DateTime? dueDate;

  const TaskCreateRequested({
    required this.title,
    this.description,
    required this.projectId,
    this.assignedTo,
    required this.priority,
    this.dueDate,
  });

  @override
  List<Object?> get props =>
      [title, description, projectId, assignedTo, priority, dueDate];
}

class TaskDeleteRequested extends TaskEvent {
  final int id;
  const TaskDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class TaskUpdateRequested extends TaskEvent {
  final int id;
  final String? title;
  final String? description;
  final String? priority;
  final DateTime? dueDate;
  final bool clearDueDate;
  final int? assignedTo;
  final bool clearAssignee;

  const TaskUpdateRequested({
    required this.id,
    this.title,
    this.description,
    this.priority,
    this.dueDate,
    this.clearDueDate = false,
    this.assignedTo,
    this.clearAssignee = false,
  });

  @override
  List<Object?> get props => [
        id, title, description, priority, dueDate,
        clearDueDate, assignedTo, clearAssignee,
      ];

      
}

class TaskModeChanged extends TaskEvent {
  final TaskMode mode;
  const TaskModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class TaskFiltersChanged extends TaskEvent {
  final TaskFilters filters;
  const TaskFiltersChanged(this.filters);
  @override
  List<Object?> get props => [filters];
}

class TaskFiltersCleared extends TaskEvent {}