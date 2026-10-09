import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/project_repository.dart';
import '../../users/data/user_repository.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

Future<void> showTaskFilterSheet(
  BuildContext context, {
  bool showAssignee = false,
}) async {
  final projectRepo = context.read<ProjectRepository>();
  final userRepo = context.read<UserRepository>();

  final results = await Future.wait([
    projectRepo.listProjects(),
    if (showAssignee)
      userRepo.listUsers(includeInactive: false)
    else
      Future.value([]),
  ]);

  final projects = results[0] as List<Project>;
  final users = results[1] as List;

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<TaskBloc>(),
      child: _FilterSheet(
        projects: projects,
        users: users,
        showAssignee: showAssignee,
      ),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final List<Project> projects;
  final List users;
  final bool showAssignee;

  const _FilterSheet({
    required this.projects,
    required this.users,
    required this.showAssignee,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TaskFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = context.read<TaskBloc>().state.filters;
  }

  void _apply() {
    context.read<TaskBloc>().add(TaskFiltersChanged(_filters));
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() => _filters = const TaskFilters());
    context.read<TaskBloc>().add(TaskFiltersCleared());
    Navigator.pop(context);
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Filter tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Status ──
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['TODO', 'IN_PROGRESS', 'REVIEW', 'COMPLETED'].map((s) {
                final selected = _filters.status == s;
                return ChoiceChip(
                  label: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: selected,
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  showCheckmark: false,
                  onSelected: (sel) {
                    setState(() {
                      _filters = sel
                          ? _filters.copyWith(status: s)
                          : _filters.copyWith(clearStatus: true);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Priority ──
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['HIGH', 'MEDIUM', 'LOW'].map((p) {
                final selected = _filters.priority == p;
                return ChoiceChip(
                  label: Text(
                    p,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: selected,
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  showCheckmark: false,
                  onSelected: (sel) {
                    setState(() {
                      _filters = sel
                          ? _filters.copyWith(priority: p)
                          : _filters.copyWith(clearPriority: true);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Project ──
            DropdownButtonFormField<int?>(
              value: _filters.projectId,
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All projects'),
                ),
                ...widget.projects.map(
                  (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _filters = v == null
                      ? _filters.copyWith(clearProject: true)
                      : _filters.copyWith(projectId: v);
                });
              },
            ),
            const SizedBox(height: 12),

            // ── Assignee (admin/manager only) ──
            if (widget.showAssignee)
              DropdownButtonFormField<int?>(
                value: _filters.assignedTo,
                decoration: const InputDecoration(
                  labelText: 'Assignee',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Anyone')),
                  ...widget.users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text('${u.displayName} (${u.role})'),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    _filters = v == null
                        ? _filters.copyWith(clearAssignee: true)
                        : _filters.copyWith(assignedTo: v);
                  });
                },
              ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }
}