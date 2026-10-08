import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../data/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repo;
  int? _currentUserId;

  TaskBloc(this._repo) : super(const TaskState()) {
    on<TasksLoadRequested>(_onLoad);
    on<TasksRefreshRequested>(_onLoad);
    on<TaskStatusUpdateRequested>(_onStatusUpdate);
    on<TaskCreateRequested>(_onCreate);
    on<TaskDeleteRequested>(_onDelete);
    on<TaskUpdateRequested>(_onUpdate);
  }

    /// Called by AppShell after login
  void setCurrentUserId(int id) => _currentUserId = id;

  Future<void> _onLoad(TaskEvent event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskListStatus.loading, clearError: true));
    try {
      final tasks = await _repo.getMyTasks();
      emit(state.copyWith(status: TaskListStatus.loaded, tasks: tasks));
    } on ApiException catch (e) {
      emit(state.copyWith(status: TaskListStatus.error, error: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: TaskListStatus.error,
          error: 'Failed to load tasks',
        ),
      );
    }
  }

  Future<void> _onStatusUpdate(
    TaskStatusUpdateRequested event,
    Emitter<TaskState> emit,
  ) async {
    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;
    final original = state.tasks[index];

    final optimistic = [...state.tasks];
    optimistic[index] = original.copyWithStatus(event.newStatus);
    emit(state.copyWith(tasks: optimistic));

    try {
      final updated = await _repo.updateStatus(event.taskId, event.newStatus);
      final merged = updated.copyWithComments(original.comments);
      final confirmed = [...state.tasks]..[index] = merged;
      emit(state.copyWith(tasks: confirmed));
    } on ApiException catch (e) {
      final rolledBack = [...state.tasks]..[index] = original;
      emit(state.copyWith(tasks: rolledBack, error: e.message));
    }
  }

Future<void> _onCreate(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final task = await _repo.createTask(
        title: event.title,
        description: event.description,
        projectId: event.projectId,
        assignedTo: event.assignedTo,
        priority: event.priority,
        dueDate: event.dueDate,
      );

      // Only prepend if the task is assigned to me
      if (_currentUserId != null && task.assignedTo == _currentUserId) {
        emit(state.copyWith(tasks: [task, ...state.tasks]));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }


  Future<void> _onDelete(
    TaskDeleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    final index = state.tasks.indexWhere((t) => t.id == event.id);
    if (index == -1) return;
    final original = state.tasks[index];

    final optimistic = [...state.tasks]..removeAt(index);
    emit(state.copyWith(tasks: optimistic));

    try {
      await _repo.deleteTask(event.id);
    } on ApiException catch (e) {
      final rolledBack = [...state.tasks]..insert(index, original);
      emit(state.copyWith(tasks: rolledBack, error: e.message));
    }
  }

  Future<void> _onUpdate(
    TaskUpdateRequested event,
    Emitter<TaskState> emit,
  ) async {
    final index = state.tasks.indexWhere((t) => t.id == event.id);
    if (index == -1) return;
    final original = state.tasks[index];

    // Optimistic
    final optimistic = original.copyWith(
      title: event.title,
      description: event.description,
      priority: event.priority,
      dueDate: event.dueDate,
      clearDueDate: event.clearDueDate,
      assignedTo: event.assignedTo,
      clearAssignee: event.clearAssignee,
    );
    final optimisticList = [...state.tasks]..[index] = optimistic;
    emit(state.copyWith(tasks: optimisticList));

    try {
      final serverTask = await _repo.updateTask(
        event.id,
        title: event.title,
        description: event.description,
        priority: event.priority,
        dueDate: event.dueDate,
        clearDueDate: event.clearDueDate,
        assignedTo: event.assignedTo,
        clearAssignee: event.clearAssignee,
      );
      final merged = serverTask.copyWithComments(original.comments);
      final confirmed = [...state.tasks]..[index] = merged;
      emit(state.copyWith(tasks: confirmed));
    } on ApiException catch (e) {
      final rolledBack = [...state.tasks]..[index] = original;
      emit(state.copyWith(tasks: rolledBack, error: e.message));
    }
  }
}
