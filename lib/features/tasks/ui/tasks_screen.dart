import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_feedback.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../data/models/task_model.dart';
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
      appBar: AppHeader(
        section: 'Tasks',
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
              onPressed: () => _openTaskForm(context),
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (previous, state) =>
            (previous.error != state.error &&
                state.error != null &&
                state.mutationStatus != TaskMutationStatus.failed),
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

Future<void> _openTaskForm(BuildContext context, {Task? existing}) async {
  final saved = await showTaskFormSheet(context, existing: existing);
  if (!context.mounted || !saved) return;

  context.read<TaskBloc>().add(const TasksRefreshRequested());
  showSuccessSnackBar(
    context,
    existing == null ? 'Task created' : 'Task updated',
    backgroundColor: existing == null
        ? const Color(0xFF10B981)
        : const Color(0xFF3B82F6),
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.mode == TaskMode.mine
                            ? Icons.coffee_outlined
                            : Icons.assignment_outlined,
                        size: 56,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.mode == TaskMode.mine
                            ? "You're all caught up"
                            : 'No tasks in your company yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.mode == TaskMode.mine
                            ? 'When someone assigns you a task,\nit will show up here.'
                            : 'Create your first task to get started.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (state.mode == TaskMode.all && canManage) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _openTaskForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('New task'),
                        ),
                      ],
                    ],
                  ),
                ),
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
          final taskBloc = context.read<TaskBloc>();
          return TaskCard(
            key: ValueKey(
                'task-${task.id}-${task.status}-${task.priority}-${task.title}'),
            task: task,
            showAssignee: state.mode == TaskMode.all,
            onTap: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
              taskBloc.add(const TasksRefreshRequested());
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
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _openTaskForm(context, existing: task);
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