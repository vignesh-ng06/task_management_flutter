import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../data/models/task_model.dart';
import 'task_detail_screen.dart';
import 'task_form_sheet.dart';
import 'widgets/task_card.dart';
import 'widgets/task_card_skeleton.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<TaskBloc>().add(const TasksLoadRequested()),
          ),
        ],
      ),
      floatingActionButton: _canManage(context)
          ? FloatingActionButton.extended(
              heroTag: 'tasks-new-task',
              onPressed: () async {
                await showTaskFormSheet(context);
                // No need to reload tasks — BLoC already prepended it
                // But if you have a project list also visible somewhere, refresh it
              },
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Loading
          if (state.status == TaskListStatus.loading && state.tasks.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 5,
              itemBuilder: (_, __) => const TaskCardSkeleton(),
            );
          }

          // Error
          if (state.status == TaskListStatus.error && state.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.error ?? 'Error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<TaskBloc>()
                        .add(const TasksLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty
          if (state.tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TaskBloc>().add(const TasksRefreshRequested());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No tasks assigned to you',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // List
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TaskBloc>().add(const TasksRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.tasks.length,
              itemBuilder: (context, i) {
                final task = state.tasks[i];
                return TaskCard(
                  key: ValueKey(
                    'task-${task.id}-${task.status}-${task.priority}-${task.title}',
                  ),
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: task.id),
                      ),
                    ).then((_) {
                      context
                          .read<TaskBloc>()
                          .add(const TasksRefreshRequested());
                    });
                  },
                  onLongPress: _canManage(context)
                      ? () => _showTaskActions(context, task)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showTaskActions(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                task.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit task'),
              onTap: () {
                Navigator.pop(sheetCtx);
                showTaskFormSheet(context, existing: task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete task',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDelete(context, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<TaskBloc>().add(TaskDeleteRequested(task.id));
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}