import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../tasks/bloc/task_bloc.dart';
import '../../tasks/bloc/task_event.dart';
import '../../tasks/ui/task_detail_screen.dart';
import '../../tasks/ui/task_form_sheet.dart';
import '../../tasks/ui/widgets/task_card.dart';
import '../data/models/project.dart';
import '../data/project_repository.dart';
import '../../auth/data/user_model.dart';
import 'project_members_sheet.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<Project> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ProjectRepository>().getProject(widget.projectId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        section: 'Project details',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: _canManage(context)
          ? FloatingActionButton.extended(
              heroTag: 'project-detail-new-task',
              onPressed: () async {
                final saved = await showTaskFormSheet(
                  context,
                  projectId: widget.projectId,
                );
                if (!context.mounted || !saved) return;
                context.read<TaskBloc>().add(const TasksRefreshRequested());
               showSuccessSnackBar(context, 'Task created successfully');
                await _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
      body: FutureBuilder<Project>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Error: ${snap.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final project = snap.data!;
          final tasks = project.tasks;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (project.description != null &&
                    project.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],

                const SizedBox(height: 16),
                _ProjectMembersRow(
                  project: project,
                  onManage: () async {
                    await showProjectMembersSheet(context, project);
                    _refresh();
                  },
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tasks (${tasks.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tasks in this project yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => TaskCard(
                      key: ValueKey(
                        'proj-task-${task.id}-${task.status}-${task.priority}',
                      ),
                      task: task,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: task.id),
                          ),
                        ).then((_) => _refresh());
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectMembersRow extends StatelessWidget {
  final Project project;
  final VoidCallback onManage;
  const _ProjectMembersRow({required this.project, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final members = project.members;
    return Row(
      children: [
        const Icon(Icons.group_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '${members.length} ${members.length == 1 ? 'member' : 'members'}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        // Avatar stack
        if (members.isNotEmpty)
          SizedBox(
            height: 28,
            width: (members.length > 4 ? 4 : members.length) * 22.0 + 8,
            child: Stack(
              children: List.generate(
                members.length > 4 ? 4 : members.length,
                (i) {
                  final u = members[i];
                  return Positioned(
                    left: i * 20.0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.indigo.shade50,
                        child: Text(
                          u.initials,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (members.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '+${members.length - 4}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        const Spacer(),
        TextButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Manage'),
        ),
      ],
    );
  }
}
