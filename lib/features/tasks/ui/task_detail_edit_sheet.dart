import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../auth/data/user_model.dart';
import '../../users/data/user_repository.dart';
import '../bloc/task_detail_bloc.dart';
import '../bloc/task_detail_event.dart';
import '../bloc/task_detail_state.dart';
import '../data/models/task_model.dart';

Future<void> showTaskDetailEditSheet(BuildContext context, Task task) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final users = await context.read<UserRepository>().listUsers(
      isActive: false,
    );
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskDetailBloc>(),
        child: _TaskDetailEditSheet(task: task, users: users),
      ),
    );
  } on ApiException catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to load assignees')),
      );
    }
  }
}

class _TaskDetailEditSheet extends StatefulWidget {
  final Task task;
  final List<User> users;

  const _TaskDetailEditSheet({required this.task, required this.users});

  @override
  State<_TaskDetailEditSheet> createState() => _TaskDetailEditSheetState();
}

class _TaskDetailEditSheetState extends State<_TaskDetailEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late int? _assigneeId;
  late String _priority;
  bool _isSaving = false;
  String? _saveError;

  bool get _titleChanged => _titleController.text.trim() != widget.task.title;
  bool get _descriptionChanged =>
      _descriptionController.text.trim() != (widget.task.description ?? '');
  bool get _dueDateChanged =>
      !_sameDate(_dueDate, widget.task.dueDate?.toLocal());
  bool get _assigneeChanged => _assigneeId != widget.task.assignedTo;
  bool get _priorityChanged => _priority != widget.task.priority;
  bool get _hasChanges =>
      _titleChanged ||
      _descriptionChanged ||
      _dueDateChanged ||
      _assigneeChanged ||
      _priorityChanged;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _dueDate = widget.task.dueDate?.toLocal();
    _assigneeId = widget.task.assignedTo;
    _priority = widget.task.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _sameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == second;
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }

    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    context.read<TaskDetailBloc>().add(
      TaskDetailUpdateRequested(
        taskId: widget.task.id,
        title: _titleChanged ? title : null,
        description: _descriptionChanged
            ? (_descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim())
            : null,
        clearDescription:
            _descriptionChanged && _descriptionController.text.trim().isEmpty,
        priority: _priorityChanged ? _priority : null,
        dueDate: _dueDateChanged ? _dueDate : null,
        clearDueDate: _dueDateChanged && _dueDate == null,
        assignedTo: _assigneeChanged ? _assigneeId : null,
        clearAssignee: _assigneeChanged && _assigneeId == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final assignedUserExists = widget.users.any(
      (user) => user.id == widget.task.assignedTo,
    );
    final assigneeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
      if (widget.task.assignedTo != null && !assignedUserExists)
        DropdownMenuItem<int?>(
          value: widget.task.assignedTo,
          child: Text(widget.task.assigneeName),
        ),
      ...widget.users.map(
        (user) => DropdownMenuItem<int?>(
          value: user.id,
          child: Text(user.displayName, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];

    return BlocListener<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) =>
          previous.status == TaskDetailStatus.updating &&
          current.status != TaskDetailStatus.updating,
      listener: (context, state) {
        if (state.error == null) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _isSaving = false;
            _saveError = state.error;
          });
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit task', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Update the task details below.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _saveError!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add more detail about this task',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _assigneeId,
                  decoration: const InputDecoration(
                    labelText: 'Assignee',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: assigneeItems,
                  onChanged: (value) => setState(() => _assigneeId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: _dueDate == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear due date',
                            onPressed: () => setState(() => _dueDate = null),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      heightFactor: 1.3,
                      child: Text(
                        _dueDate == null
                            ? 'No due date'
                            : MaterialLocalizations.of(context)
                                  .formatMediumDate(_dueDate!.toLocal()),
                        style: _dueDate == null
                            ? TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
