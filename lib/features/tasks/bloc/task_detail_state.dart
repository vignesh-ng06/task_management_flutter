import 'package:equatable/equatable.dart';
import '../data/models/task_model.dart';
import '../data/models/comment.dart';

enum TaskDetailStatus { initial, loading, loaded, error, updating }

class TaskDetailState extends Equatable {
  final TaskDetailStatus status;
  final Task? task;
  final List<Comment> comments;
  final bool commentsLoading;
  final bool postingComment;
  final String? error;

  const TaskDetailState({
    this.status = TaskDetailStatus.initial,
    this.task,
    this.comments = const [],
    this.commentsLoading = false,
    this.postingComment = false,
    this.error,
  });

  TaskDetailState copyWith({
    TaskDetailStatus? status,
    Task? task,
    List<Comment>? comments,
    bool? commentsLoading,
    bool? postingComment,
    String? error,
    bool clearError = false,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      comments: comments ?? this.comments,
      commentsLoading: commentsLoading ?? this.commentsLoading,
      postingComment: postingComment ?? this.postingComment,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, task, comments, commentsLoading, postingComment, error];
}