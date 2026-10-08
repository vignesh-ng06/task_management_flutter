import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/task_detail_bloc.dart';
import '../bloc/task_detail_event.dart';
import '../bloc/task_detail_state.dart';
import '../data/models/comment.dart';
import '../data/models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TaskDetailBloc(context.read())..add(TaskDetailLoadRequested(taskId)),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: BlocConsumer<TaskDetailBloc, TaskDetailState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TaskDetailStatus.loading && state.task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.task == null) {
            return const Center(child: Text('Task not found'));
          }
          return _TaskBody(
            task: state.task!,
            comments: state.comments,
            isUpdating: state.status == TaskDetailStatus.updating,
            commentsLoading: state.commentsLoading,
            postingComment: state.postingComment,
          );
        },
      ),
    );
  }
}

class _TaskBody extends StatelessWidget {
  final Task task;
  final List<Comment> comments;
  final bool isUpdating;
  final bool commentsLoading;
  final bool postingComment;

  const _TaskBody({
    required this.task,
    required this.comments,
    required this.isUpdating,
    required this.commentsLoading,
    required this.postingComment,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = task.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                const SizedBox(height: 24),

                _Section(title: 'Status', child: _statusWidget(context)),
                const SizedBox(height: 16),
                _Section(
                  title: 'Priority',
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _priorityColor(task.priority),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Section(title: 'Project', child: Text(task.projectName)),
                const SizedBox(height: 16),
                _Section(title: 'Due date', child: Text(task.dueDateLabel)),
                const SizedBox(height: 16),
                _Section(title: 'Assignee', child: Text(task.assigneeName)),
                const SizedBox(height: 16),
                _Section(
                  title: 'Created',
                  child: Text(
                    '${localizations.formatMediumDate(createdAt)} at '
                    '${localizations.formatTimeOfDay(
                      TimeOfDay.fromDateTime(createdAt),
                      alwaysUse24HourFormat: false,
                    )}',
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),

                // ── Comments header ──
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${comments.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Comments list ──
                if (commentsLoading && comments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No comments yet. Be the first to comment.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...comments.map((c) => _CommentTile(comment: c)).toList(),
              ],
            ),
          ),
        ),

        // ── Comment input at the bottom ──
        _CommentInput(
          taskId: task.id,
          posting: postingComment,
        ),
      ],
    );
  }

  Widget _statusWidget(BuildContext context) {
    final statuses = ['TODO', 'IN_PROGRESS', 'REVIEW', 'COMPLETED'];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: task.status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: isUpdating
                ? null
                : (value) {
                    if (value != null && value != task.status) {
                      context
                          .read<TaskDetailBloc>()
                          .add(TaskDetailStatusChanged(task.id, value));
                    }
                  },
          ),
        ),
        if (isUpdating) ...[
          const SizedBox(width: 12),
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      _relativeTime(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (comment.authorRole == 'admin')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.message, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return dt.toLocal().toString().split(' ')[0];
  }
}

class _CommentInput extends StatefulWidget {
  final int taskId;
  final bool posting;
  const _CommentInput({required this.taskId, required this.posting});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.posting) return;

    context.read<TaskDetailBloc>().add(TaskCommentSubmitted(widget.taskId, text));
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Write a comment…',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.posting ? null : _send,
              icon: widget.posting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}