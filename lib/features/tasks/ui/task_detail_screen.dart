import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_feedback.dart';

import '../../../core/widgets/app_header.dart';
import '../bloc/task_detail_bloc.dart';
import '../bloc/task_detail_event.dart';
import '../bloc/task_detail_state.dart';
import '../data/models/comment.dart';
import '../data/models/task_model.dart';
import 'task_detail_edit_sheet.dart';
import 'widgets/activity_timeline.dart';
import '../../auth/bloc/auth_bloc.dart';

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
    final role = context.watch<AuthBloc>().state.user?.role;
    final canEditTask = role == 'admin' || role == 'manager';

    return Scaffold(
      appBar: AppHeader(
        section: 'Task details',
        actions: [
          if (canEditTask)
            BlocBuilder<TaskDetailBloc, TaskDetailState>(
              builder: (context, state) => state.task?.isActive == true
                  ? IconButton(
                      tooltip: 'Edit task',
                      onPressed: state.status == TaskDetailStatus.updating
                          ? null
                          : () => showTaskDetailEditSheet(context, state.task!),
                      icon: const Icon(Icons.edit_outlined),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
      body: BlocConsumer<TaskDetailBloc, TaskDetailState>(
        listenWhen: (previous, state) =>
            (previous.status == TaskDetailStatus.updating &&
                state.status == TaskDetailStatus.loaded &&
                state.error == null) ||
            (previous.error != state.error &&
                state.error != null &&
                previous.status != TaskDetailStatus.updating),
        listener: (context, state) {
          if (state.status == TaskDetailStatus.loaded && state.error == null) {
            showSuccessSnackBar(
              context,
              'Task updated',
              backgroundColor: const Color(0xFF3B82F6),
            );
          } else if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.status == TaskDetailStatus.loading && state.task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.task == null) {
            return const Center(child: Text('Task not found'));
          }
          final task = state.task!;
          return _TaskBody(
            task: task,
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskBadge(
                      label: task.status.replaceAll('_', ' '),
                      icon: Icons.radio_button_checked,
                      color: colors.primary,
                      isDark: isDark,
                    ),
                    _TaskBadge(
                      label: '${task.priority} priority',
                      icon: Icons.flag_outlined,
                      color: _priorityColor(task.priority),
                      isDark: isDark,
                    ),
                    if (task.isOverdue)
                      _TaskBadge(
                        label: 'Overdue',
                        icon: Icons.warning_amber_rounded,
                        color: colors.error,
                        isDark: isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                if (task.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  _TaskDescription(description: task.description!),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _Section(title: 'Status', child: _statusWidget(context)),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 16,
                            children: [
                              _InfoItem(
                                width: itemWidth,
                                icon: Icons.folder_outlined,
                                label: 'Project',
                                value: task.projectName,
                              ),
                              _InfoItem(
                                width: itemWidth,
                                icon: Icons.person_outline,
                                label: 'Assignee',
                                value: task.assigneeName,
                              ),
                              _InfoItem(
                                width: itemWidth,
                                icon: task.isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.calendar_today_outlined,
                                label: 'Due date',
                                value: task.dueDateLabel,
                                valueColor: task.isOverdue
                                    ? colors.error
                                    : null,
                              ),
                              _InfoItem(
                                width: itemWidth,
                                icon: Icons.schedule_outlined,
                                label: 'Created',
                                value:
                                    '${localizations.formatMediumDate(createdAt)} at '
                                    '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(createdAt), alwaysUse24HourFormat: false)}',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _DetailSectionHeader(
                  icon: Icons.chat_bubble_outline,
                  title: 'Comments',
                  count: comments.length,
                ),
                const SizedBox(height: 12),

                if (commentsLoading && comments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (comments.isEmpty)
                  _EmptyDetailMessage(
                    icon: Icons.forum_outlined,
                    text: 'No comments yet. Start the conversation.',
                  )
                else
                  ...comments.map(
                    (c) =>
                        _CommentTile(comment: c, allowActions: task.isActive),
                  ),

                const SizedBox(height: 18),
                _DetailSectionHeader(
                  icon: Icons.history,
                  title: 'Activity',
                  count: task.activities.length,
                ),
                const SizedBox(height: 12),
                ActivityTimeline(activities: task.activities),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Comment input at the bottom ──
        if (task.isActive)
          _CommentInput(taskId: task.id, posting: postingComment)
        else
          const _InactiveTaskNotice(),
      ],
    );
  }

  Widget _statusWidget(BuildContext context) {
    final statuses = ['TODO', 'IN_PROGRESS', 'REVIEW', 'COMPLETED'];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: task.status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: isUpdating || !task.isActive
                ? null
                : (value) {
                    if (value != null && value != task.status) {
                      context.read<TaskDetailBloc>().add(
                        TaskDetailStatusChanged(task.id, value),
                      );
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

class _TaskDescription extends StatefulWidget {
  final String description;

  const _TaskDescription({required this.description});

  @override
  State<_TaskDescription> createState() => _TaskDescriptionState();
}

class _TaskDescriptionState extends State<_TaskDescription> {
  static const _previewLineCount = 7;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: colors.onSurface, height: 1.55, letterSpacing: 0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: widget.description, style: textStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: _previewLineCount,
              )..layout(maxWidth: constraints.maxWidth);
              final hasMore = painter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _expanded
                      ? SelectableText(widget.description, style: textStyle)
                      : Text(
                          widget.description,
                          style: textStyle,
                          maxLines: _previewLineCount,
                          overflow: TextOverflow.ellipsis,
                        ),
                  if (hasMore)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_expanded ? 'Show less' : 'Show more'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _TaskBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surface.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? colors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _DetailSectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDetailMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyDetailMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool allowActions;

  const _CommentTile({required this.comment, required this.allowActions});

  bool _canEdit(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return user != null && user.id == comment.userId;
  }

  bool _canDelete(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return false;
    return user.id == comment.userId || user.role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canEdit = allowActions && _canEdit(context);
    final canDelete = allowActions && _canDelete(context);
    final hasActions = canEdit || canDelete;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.surfaceContainerLow
            : Colors.grey[100],
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (comment.authorRole == 'admin') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                      ],
                    ),
                    Text(
                      _relativeTime(comment.createdAt) +
                          (comment.wasEdited ? ' · edited' : ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colors.onSurfaceVariant
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActions)
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showActions(context, canEdit, canDelete),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            comment.message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurface, height: 1.45),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, bool canEdit, bool canDelete) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit comment'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEditDialog(context);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: comment.message);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit comment'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(dialogCtx);
              context.read<TaskDetailBloc>().add(
                TaskCommentUpdateRequested(comment.id, text),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<TaskDetailBloc>().add(
                TaskCommentDeleteRequested(comment.id),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
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

    context.read<TaskDetailBloc>().add(
      TaskCommentSubmitted(widget.taskId, text),
    );
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? colors.surface
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.outlineVariant
                  : Colors.grey.shade300,
            ),
          ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveTaskNotice extends StatelessWidget {
  const _InactiveTaskNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Text(
          'This task is inactive and can only be viewed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? colors.onSurfaceVariant
                : Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
