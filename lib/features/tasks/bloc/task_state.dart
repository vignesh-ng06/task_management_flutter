import 'package:equatable/equatable.dart';
import '../data/models/task_model.dart';

enum TaskListStatus { initial, loading, loaded, error }
enum TaskMode { mine, all }

class TaskFilters extends Equatable {
  final String? status;      // null = all
  final String? priority;    // 'HIGH' | 'MEDIUM' | 'LOW' | null
  final int? projectId;
  final int? assignedTo;
  final String search;

  const TaskFilters({
    this.status,
    this.priority,
    this.projectId,
    this.assignedTo,
    this.search = '',
  });

  bool get isEmpty =>
      status == null &&
      priority == null &&
      projectId == null &&
      assignedTo == null &&
      search.isEmpty;

  TaskFilters copyWith({
    String? status,
    String? priority,
    int? projectId,
    int? assignedTo,
    String? search,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearProject = false,
    bool clearAssignee = false,
  }) {
    return TaskFilters(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      assignedTo: clearAssignee ? null : (assignedTo ?? this.assignedTo),
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [status, priority, projectId, assignedTo, search];
}

class TaskState extends Equatable {
  final TaskListStatus status;
  final List<Task> tasks;
  final TaskMode mode;
  final TaskFilters filters;
  final String? error;

  const TaskState({
    this.status = TaskListStatus.initial,
    this.tasks = const [],
    this.mode = TaskMode.mine,
    this.filters = const TaskFilters(),
    this.error,
  });

  TaskState copyWith({
    TaskListStatus? status,
    List<Task>? tasks,
    TaskMode? mode,
    TaskFilters? filters,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      mode: mode ?? this.mode,
      filters: filters ?? this.filters,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, tasks, mode, filters, error];
}