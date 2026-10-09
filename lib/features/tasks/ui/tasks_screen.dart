import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'task_detail_screen.dart';
import 'task_filter_sheet.dart';
import 'task_form_sheet.dart';
import 'widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
  }

  @override
Widget build(BuildContext context) {
  return BlocListener<TaskBloc, TaskState>(
    listener: (context, state) {
      if (state.filters.search.isEmpty && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      } else if (state.filters.search != _searchCtrl.text &&
          state.filters.search.isNotEmpty) {
        _searchCtrl.text = state.filters.search;
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
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
              onPressed: () => showTaskFormSheet(context),
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
          final canManage = _canManage(context);

          return Column(
            children: [
              // ── Mode toggle (admin/manager only) ──
              if (canManage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SegmentedButton<TaskMode>(
                    segments: const [
                      ButtonSegment(
                        value: TaskMode.mine,
                        label: Text('My Tasks'),
                        icon: Icon(Icons.person_outline, size: 16),
                      ),
                      ButtonSegment(
                        value: TaskMode.all,
                        label: Text('All Tasks'),
                        icon: Icon(Icons.groups_outlined, size: 16),
                      ),
                    ],
                    selected: {state.mode},
                    onSelectionChanged: (s) => context
                        .read<TaskBloc>()
                        .add(TaskModeChanged(s.first)),
                  ),
                ),

              // ── Search + Filters bar (always visible) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search tasks…',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (v) {
                          final newFilters =
                              state.filters.copyWith(search: v.trim());
                          context
                              .read<TaskBloc>()
                              .add(TaskFiltersChanged(newFilters));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => showTaskFilterSheet(context, showAssignee: canManage && state.mode == TaskMode.all),
                          icon: const Icon(Icons.tune, size: 20),
                          tooltip: 'Filters',
                        ),
                        if (!state.filters.isEmpty)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '${_activeCount(state.filters)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Body ──
              Expanded(
                child: _buildBody(context, state, canManage),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  int _activeCount(TaskFilters f) {
    int c = 0;
    if (f.status != null) c++;
    if (f.priority != null) c++;
    if (f.projectId != null) c++;
    if (f.assignedTo != null) c++;
    if (f.search.isNotEmpty) c++;
    return c;
  }

  Widget _buildBody(BuildContext context, TaskState state, bool canManage) {
    if (state.status == TaskListStatus.loading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == TaskListStatus.error && state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.error ?? 'Error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<TaskBloc>().add(const TasksLoadRequested()),
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
            SizedBox(height: 180),
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tasks found',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
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
            key: ValueKey(
                'task-${task.id}-${task.status}-${task.priority}-${task.title}'),
            task: task,
            showAssignee: state.mode == TaskMode.all,
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
            onLongPress: canManage
                ? () => _showTaskActions(context, task)
                : null,
          );
        },
      ),
    );
  }

  void _showTaskActions(BuildContext context, task) {
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
                context
                    .read<TaskBloc>()
                    .add(TaskDeleteRequested(task.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}