import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/api/api_client.dart';
import 'package:task_app/features/tasks/data/task_repository.dart';

import 'task_detail_event.dart';
import 'task_detail_state.dart';

import '../data/models/comment.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  final TaskRepository _repo;

  TaskDetailBloc(this._repo) : super(const TaskDetailState()) {
    on<TaskDetailLoadRequested>(_onLoad);
    on<TaskDetailStatusChanged>(_onStatusChange);
    on<TaskDetailUpdateRequested>(_onUpdate);
    on<TaskCommentsLoadRequested>(_onLoadComments);
    on<TaskCommentSubmitted>(_onSubmitComment);
    on<TaskCommentUpdateRequested>(_onUpdateComment);
    on<TaskCommentDeleteRequested>(_onDeleteComment);
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
      // Preserve comments that the update response doesn't include.
      final merged = updated.copyWith(
        comments: state.task?.comments ?? const [],
        activities: state.task?.activities ?? const [],
      );
      emit(state.copyWith(status: TaskDetailStatus.loaded, task: merged));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: TaskDetailStatus.loaded,
        error: e.message,
      ));
    }
  }

  Future<void> _onUpdate(
    TaskDetailUpdateRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final original = state.task;
    if (original == null) return;

    emit(state.copyWith(status: TaskDetailStatus.updating, clearError: true));
    try {
      final updated = await _repo.updateTask(
        event.taskId,
        title: event.title,
        description: event.description,
        dueDate: event.dueDate,
        clearDueDate: event.clearDueDate,
        assignedTo: event.assignedTo,
        clearAssignee: event.clearAssignee,
      );
      final merged = updated.copyWith(
        comments: original.comments,
        activities: original.activities,
      );
      emit(state.copyWith(status: TaskDetailStatus.loaded, task: merged));
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: TaskDetailStatus.loaded, error: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TaskDetailStatus.loaded,
          error: 'Failed to update task',
        ),
      );
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



  Future<void> _onUpdateComment(
    TaskCommentUpdateRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    // Optimistic update
    final original = state.comments;
    final optimistic = original
        .map(
          (c) => c.id == event.commentId
              ? Comment(
                  id: c.id,
                  taskId: c.taskId,
                  userId: c.userId,
                  message: event.message,
                  createdAt: c.createdAt,
                  updatedAt: DateTime.now(),
                  authorName: c.authorName,
                  authorEmail: c.authorEmail,
                  authorRole: c.authorRole,
                )
              : c,
        )
        .toList();
    emit(state.copyWith(comments: optimistic));

    try {
      final updated = await _repo.updateComment(event.commentId, event.message);
      final confirmed = state.comments
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      emit(state.copyWith(comments: confirmed));
    } on ApiException catch (e) {
      emit(state.copyWith(comments: original, error: e.message));
    }
  }

  Future<void> _onDeleteComment(
    TaskCommentDeleteRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final original = state.comments;
    final optimistic = original.where((c) => c.id != event.commentId).toList();
    emit(state.copyWith(comments: optimistic));

    try {
      await _repo.deleteComment(event.commentId);
    } on ApiException catch (e) {
      emit(state.copyWith(comments: original, error: e.message));
    }
  }

}