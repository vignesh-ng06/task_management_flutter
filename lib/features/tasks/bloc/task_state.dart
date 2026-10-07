import 'package:equatable/equatable.dart';
import '../data/models/task_model.dart';

enum TaskListStatus { initial, loading, loaded, error }

class TaskState extends Equatable {
  final TaskListStatus status;
  final List<Task> tasks;
  final String? error;

  const TaskState({
    this.status = TaskListStatus.initial,
    this.tasks = const [],
    this.error,
  });

  TaskState copyWith({
    TaskListStatus? status,
    List<Task>? tasks,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, tasks, error];
}