import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../data/models/task_model.dart';
import 'widgets/task_card.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notifications screen coming next
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state.status == TaskListStatus.loading && state.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TaskListStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
          if (state.tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TaskBloc>().add(const TasksRefreshRequested());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No tasks assigned to you')),
                ],
              ),
            );
          }
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
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: task.id),
                      ),
                    ).then((_) {
                      // Refresh the list when coming back, in case status changed
                      context.read<TaskBloc>().add(
                        const TasksRefreshRequested(),
                      );
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}