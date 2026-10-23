import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/user_model.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/project_repository.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../data/models/task_model.dart';

Future<bool> showTaskFormSheet(
  BuildContext context, {
  Task? existing,
  int? projectId,
}) async {
  final projectRepo = context.read<ProjectRepository>();
  final messenger = ScaffoldMessenger.of(context);
  late final List<Project> projects;
  try {
    projects = await projectRepo.listProjects();
  } on ApiException catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to load the task form: $error')),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MultiBlocProvider(
          providers: [BlocProvider.value(value: context.read<TaskBloc>())],
          child: _TaskFormSheet(
            existing: existing,
            initialProjectId: projectId,
            projects: projects,
            projectRepo: projectRepo,
          ),
        ),
      ) ??
      false;
}

class _TaskFormSheet extends StatefulWidget {
  final Task? existing;
  final int? initialProjectId;
  final List<Project> projects;
  final ProjectRepository projectRepo;

  const _TaskFormSheet({
    this.existing,
    this.initialProjectId,
    required this.projects,
    required this.projectRepo,
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
  bool _dueDateAutoSet = false;
  bool _isSaving = false;
  String? _saveError;

  // Assignee list for the current project
  List<User> _availableAssignees = [];
  bool _loadingMembers = false;

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
    } else if (widget.initialProjectId != null &&
        widget.projects.any((p) => p.id == widget.initialProjectId)) {
      _projectId = widget.initialProjectId;
    } else if (widget.projects.isNotEmpty) {
      _projectId = widget.projects.first.id;
    }

    if (!isEdit && _dueDate == null) {
      _dueDate = DateTime.now().add(const Duration(days: 1));
      _dueDateAutoSet = true;
    }

    if (_projectId != null) {
      _loadMembersForProject(_projectId!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembersForProject(int projectId) async {
    setState(() {
      _loadingMembers = true;
      _availableAssignees = [];
    });

    try {
      final project = await widget.projectRepo.getProject(projectId);
      if (!mounted) return;

      final currentUserId = context.read<AuthBloc>().state.user?.id;
      final assignees = project.members.where((user) => user.isActive).toList();
      const roleOrder = {'manager': 0, 'employee': 1, 'admin': 2};
      assignees.sort((a, b) {
        final aIsCurrentUser = a.id == currentUserId;
        final bIsCurrentUser = b.id == currentUserId;
        if (aIsCurrentUser != bIsCurrentUser) {
          return aIsCurrentUser ? -1 : 1;
        }

        final roleComparison = (roleOrder[a.role] ?? roleOrder.length)
            .compareTo(roleOrder[b.role] ?? roleOrder.length);
        if (roleComparison != 0) return roleComparison;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      setState(() {
        _availableAssignees = assignees;

        // If current assignee is no longer in the project, clear it
        if (_assigneeId != null &&
            !_availableAssignees.any((u) => u.id == _assigneeId)) {
          _assigneeId = null;
        }
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableAssignees = [];
        _loadingMembers = false;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateAutoSet = false;
      });
    }
  }

  void _submit() {
    if (_isSaving) return;
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

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    if (isEdit) {
      context.read<TaskBloc>().add(
        TaskUpdateRequested(
          id: widget.existing!.id,
          title: title,
          description: desc.isEmpty ? null : desc,
          clearDescription: desc.isEmpty,
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
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (previous, current) =>
          (current.mutationStatus == TaskMutationStatus.succeeded ||
              current.mutationStatus == TaskMutationStatus.failed) &&
          previous.mutationStatus != current.mutationStatus,
      listener: (context, state) {
        if (state.mutationStatus == TaskMutationStatus.succeeded) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isSaving = false;
            _saveError = state.mutationMessage ?? 'Unable to save this task.';
          });
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit task' : 'New task',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              if (_saveError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                initialValue: _projectId,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                items: widget.projects
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _projectId = v;
                    _assigneeId = null;
                  });
                  _loadMembersForProject(v);
                },
              ),
              const SizedBox(height: 12),

              // Assignee dropdown — driven by project members
              _buildAssigneeField(),
              const SizedBox(height: 12),

              // Priority selector
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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
                            onPressed: () => setState(() {
                              _dueDate = null;
                              _dueDateAutoSet = false;
                            }),
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
              if (_dueDateAutoSet) ...[
                const SizedBox(height: 4),
                const Text(
                  'Defaults to tomorrow — change if needed',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeField() {
    // Still loading members
    if (_loadingMembers) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Assign to (optional)',
          border: OutlineInputBorder(),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Loading members…', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Project has no members
    if (_availableAssignees.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Assign to (optional)',
          border: OutlineInputBorder(),
          helperText: 'No members in this project yet',
        ),
        child: const Text('Unassigned', style: TextStyle(color: Colors.grey)),
      );
    }

    // Project members available
    return DropdownButtonFormField<int?>(
      initialValue: _assigneeId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assign to (optional)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Unassigned')),
        ..._availableAssignees.map(
          (u) => DropdownMenuItem(
            value: u.id,
            child: Text(
              '${u.displayName} · ${u.role}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _assigneeId = v),
    );
  }
}
