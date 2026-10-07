import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repo;

  TaskBloc(this._repo) : super(const TaskState()) {
    on<TasksLoadRequested>(_onLoad);
    on<TasksRefreshRequested>(_onLoad);
    on<TaskStatusUpdateRequested>(_onStatusUpdate);
  }

  Future<void> _onLoad(TaskEvent event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskListStatus.loading, clearError: true));
    try {
      final tasks = await _repo.getMyTasks();
      emit(state.copyWith(status: TaskListStatus.loaded, tasks: tasks));
    } on ApiException catch (e) {
      emit(state.copyWith(status: TaskListStatus.error, error: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: TaskListStatus.error,
        error: 'Failed to load tasks',
      ));
    }
  }

  Future<void> _onStatusUpdate(
    TaskStatusUpdateRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final updated = await _repo.updateStatus(event.taskId, event.newStatus);
      final newList = state.tasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList();
      emit(state.copyWith(tasks: newList));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}