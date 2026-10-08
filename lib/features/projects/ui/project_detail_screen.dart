import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../tasks/ui/task_detail_screen.dart';
import '../../tasks/ui/task_form_sheet.dart';
import '../../tasks/ui/widgets/task_card.dart';
import '../data/models/project.dart';
import '../data/project_repository.dart';

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
      appBar: AppBar(
        title: const Text('Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: _canManage(context)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await showTaskFormSheet(context);
                _refresh();
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
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
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
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (project.description != null &&
                    project.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
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
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                          Icon(Icons.inbox_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No tasks in this project yet',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                else
                  ...tasks.map((task) => TaskCard(
                        key: ValueKey(
                            'proj-task-${task.id}-${task.status}-${task.priority}'),
                        task: task,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskDetailScreen(taskId: task.id),
                            ),
                          ).then((_) => _refresh());
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}