import 'package:equatable/equatable.dart';

abstract class TaskDetailEvent extends Equatable {
  const TaskDetailEvent();
  @override
  List<Object?> get props => [];
}

class TaskDetailLoadRequested extends TaskDetailEvent {
  final int taskId;
  const TaskDetailLoadRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class TaskDetailStatusChanged extends TaskDetailEvent {
  final int taskId;
  final String newStatus;
  const TaskDetailStatusChanged(this.taskId, this.newStatus);
  @override
  List<Object?> get props => [taskId, newStatus];
}



class TaskCommentsLoadRequested extends TaskDetailEvent {
  final int taskId;
  const TaskCommentsLoadRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class TaskCommentSubmitted extends TaskDetailEvent {
  final int taskId;
  final String message;
  const TaskCommentSubmitted(this.taskId, this.message);
  @override
  List<Object?> get props => [taskId, message];
}


class TaskCommentUpdateRequested extends TaskDetailEvent {
  final int commentId;
  final String message;
  const TaskCommentUpdateRequested(this.commentId, this.message);
  @override
  List<Object?> get props => [commentId, message];
}

class TaskCommentDeleteRequested extends TaskDetailEvent {
  final int commentId;
  const TaskCommentDeleteRequested(this.commentId);
  @override
  List<Object?> get props => [commentId];
}