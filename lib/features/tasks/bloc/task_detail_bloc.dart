import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/task_repository.dart';
import 'task_detail_event.dart';
import 'task_detail_state.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  final TaskRepository _repo;

  TaskDetailBloc(this._repo) : super(const TaskDetailState()) {
    on<TaskDetailLoadRequested>(_onLoad);
    on<TaskDetailStatusChanged>(_onStatusChange);
    on<TaskCommentsLoadRequested>(_onLoadComments);
    on<TaskCommentSubmitted>(_onSubmitComment);
  }

  Future<void> _onLoad(
    TaskDetailLoadRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: TaskDetailStatus.loading, clearError: true));
    try {
      final task = await _repo.getTask(event.taskId);
      emit(state.copyWith(status: TaskDetailStatus.loaded, task: task));
      add(TaskCommentsLoadRequested(event.taskId));
    } on ApiException catch (e) {
      emit(state.copyWith(status: TaskDetailStatus.error, error: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: TaskDetailStatus.error,
        error: 'Failed to load task',
      ));
    }
  }

  Future<void> _onStatusChange(
    TaskDetailStatusChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: TaskDetailStatus.updating, clearError: true));
    try {
      final updated = await _repo.updateStatus(event.taskId, event.newStatus);
      emit(state.copyWith(status: TaskDetailStatus.loaded, task: updated));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: TaskDetailStatus.loaded,
        error: e.message,
      ));
    }
  }

  Future<void> _onLoadComments(
    TaskCommentsLoadRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(commentsLoading: true, clearError: true));
    try {
      final comments = await _repo.getComments(event.taskId);
      emit(state.copyWith(commentsLoading: false, comments: comments));
    } on ApiException catch (e) {
      emit(state.copyWith(commentsLoading: false, error: e.message));
    }
  }

  Future<void> _onSubmitComment(
    TaskCommentSubmitted event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(postingComment: true, clearError: true));
    try {
      final comment = await _repo.addComment(event.taskId, event.message);
      emit(state.copyWith(
        postingComment: false,
        comments: [...state.comments, comment],
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(postingComment: false, error: e.message));
    }
  }
}