import 'package:equatable/equatable.dart';

import '../data/models/task_model.dart';

enum TaskListStatus { initial, loading, loaded, error }

enum TaskMode { mine, all }

enum TaskMutationStatus { idle, creating, updating, succeeded, failed }

class TaskFilters extends Equatable {
  final String? status; // null = all
  final String? priority; // 'HIGH' | 'MEDIUM' | 'LOW' | null
  final int? projectId;
  final int? assignedTo;
  final String search;
  final bool includeInactive;

  const TaskFilters({
    this.status,
    this.priority,
    this.projectId,
    this.assignedTo,
    this.search = '',
    this.includeInactive = false,
  });

  bool get isEmpty =>
      status == null &&
      priority == null &&
      projectId == null &&
      assignedTo == null &&
      search.isEmpty &&
      !includeInactive;

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
    bool? includeInactive,
  }) {
    return TaskFilters(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      assignedTo: clearAssignee ? null : (assignedTo ?? this.assignedTo),
      search: search ?? this.search,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }

  @override
  List<Object?> get props => [
    status,
    priority,
    projectId,
    assignedTo,
    search,
    includeInactive,
  ];
}

class TaskState extends Equatable {
  final TaskListStatus status;
  final List<Task> tasks;
  final TaskMode mode;
  final TaskFilters filters;
  final String? error;
  final int? total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final TaskMutationStatus mutationStatus;
  final String? mutationMessage;

  const TaskState({
    this.status = TaskListStatus.initial,
    this.tasks = const [],
    this.mode = TaskMode.mine,
    this.filters = const TaskFilters(),
    this.error,
    this.total,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.mutationStatus = TaskMutationStatus.idle,
    this.mutationMessage,
  });

  TaskState copyWith({
    TaskListStatus? status,
    List<Task>? tasks,
    TaskMode? mode,
    TaskFilters? filters,
    String? error,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    TaskMutationStatus? mutationStatus,
    String? mutationMessage,
    bool clearError = false,
    bool clearTotal = false,
    bool clearMutationMessage = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      mode: mode ?? this.mode,
      filters: filters ?? this.filters,
      error: clearError ? null : (error ?? this.error),
      total: clearTotal ? null : (total ?? this.total),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      mutationMessage: clearMutationMessage
          ? null
          : (mutationMessage ?? this.mutationMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    mode,
    filters,
    error,
    total,
    page,
    hasMore,
    isLoadingMore,
    mutationStatus,
    mutationMessage,
  ];
}
