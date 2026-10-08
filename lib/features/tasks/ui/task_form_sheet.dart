import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/user_model.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/project_repository.dart';
import '../../users/data/user_repository.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../data/models/task_model.dart';
import '../data/task_repository.dart';

Future<void> showTaskFormSheet(BuildContext context, {Task? existing}) async {
  // Preload projects and users in parallel
  final projectRepo = context.read<ProjectRepository>();
  final userRepo = context.read<UserRepository>();

  final results = await Future.wait([
    projectRepo.listProjects(),
    userRepo.listUsers(includeInactive: false),
  ]);

  final projects = results[0] as List<Project>;
  final users = results[1] as List<User>;

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<TaskBloc>()),
      ],
      child: _TaskFormSheet(
        existing: existing,
        projects: projects,
        users: users,
      ),
    ),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final Task? existing;
  final List<Project> projects;
  final List<User> users;

  const _TaskFormSheet({
    this.existing,
    required this.projects,
    required this.users,
  });

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _projectId;
  int? _assigneeId;
  String _priority = 'MEDIUM';
  DateTime? _dueDate;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description ?? '';
      _projectId = widget.existing!.project?['id'] as int?;
      _assigneeId = widget.existing!.assignedTo;
      _priority = widget.existing!.priority;
      _dueDate = widget.existing!.dueDate;
    } else if (widget.projects.isNotEmpty) {
      _projectId = widget.projects.first.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.length < 2) {
      _toast('Title must be at least 2 characters');
      return;
    }
    if (_projectId == null) {
      _toast('Please select a project');
      return;
    }

if (isEdit) {
      context.read<TaskBloc>().add(
        TaskUpdateRequested(
          id: widget.existing!.id,
          title: title,
          description: desc.isEmpty ? null : desc,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          assignedTo: _assigneeId,
          clearAssignee: _assigneeId == null,
        ),
      );
    } else {
      context.read<TaskBloc>().add(
        TaskCreateRequested(
          title: title,
          description: desc.isEmpty ? null : desc,
          projectId: _projectId!,
          assignedTo: _assigneeId,
          priority: _priority,
          dueDate: _dueDate,
        ),
      );
    }

    Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit task' : 'New task',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Project dropdown
            DropdownButtonFormField<int>(
              value: _projectId,
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
              items: widget.projects
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _projectId = v),
            ),
            const SizedBox(height: 12),

            // Assignee dropdown
            DropdownButtonFormField<int?>(
              value: _assigneeId,
              decoration: const InputDecoration(
                labelText: 'Assign to (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...widget.users.map(
                  (u) => DropdownMenuItem(
                    value: u.id,
                    child: Text('${u.displayName} (${u.role})'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 12),

            // Priority selector
            const Text('Priority',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'HIGH', label: Text('High')),
                ButtonSegment(value: 'MEDIUM', label: Text('Medium')),
                ButtonSegment(value: 'LOW', label: Text('Low')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 16),

            // Due date
            InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due date',
                  border: const OutlineInputBorder(),
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dueDate == null
                      ? 'No due date'
                      : _dueDate!.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    color: _dueDate == null ? Colors.grey : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(isEdit ? 'Save changes' : 'Create task'),
            ),
          ],
        ),
      ),
    );
  }
}
