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
  final ScrollController _scrollController = ScrollController();

  static const _loadMoreThreshold = 400.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }

    final bloc = context.read<TaskBloc>();
    if (bloc.state.hasMore && !bloc.state.isLoadingMore) {
      bloc.add(const TasksLoadMoreRequested());
    }
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
        appBar: AppHeader(section: 'Tasks'),
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
                      onSelectionChanged: (s) => context.read<TaskBloc>().add(
                        TaskModeChanged(s.first),
                      ),
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
                            final newFilters = state.filters.copyWith(
                              search: v.trim(),
                            );
                            context.read<TaskBloc>().add(
                              TaskFiltersChanged(newFilters),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => showTaskFilterSheet(
                              context,
                              showAssignee:
                                  canManage && state.mode == TaskMode.all,
                            ),
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

                if (state.filters.includeInactive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Inactive tasks (${state.tasks.where((task) => !task.isActive).length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildAppliedFilterChips(context, state.filters),

                const SizedBox(height: 8),

                // ── Body ──
                Expanded(child: _buildBody(context, state, canManage)),
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
    if (f.includeInactive) c++;
    return c;
  }

  Widget _buildAppliedFilterChips(BuildContext context, TaskFilters filters) {
    final chips = <Widget>[];

    void addChip(String label, VoidCallback onDeleted) {
      chips.add(
        Chip(
          label: Text(label),
          onDeleted: onDeleted,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    void update(TaskFilters next) {
      context.read<TaskBloc>().add(TaskFiltersChanged(next));
    }

    if (filters.search.isNotEmpty) {
      addChip('Search: ${filters.search}', () {
        _searchCtrl.clear();
        update(filters.copyWith(search: ''));
      });
    }
    if (filters.status != null) {
      addChip(
        filters.status!,
        () => update(filters.copyWith(clearStatus: true)),
      );
    }
    if (filters.priority != null) {
      addChip(
        filters.priority!,
        () => update(filters.copyWith(clearPriority: true)),
      );
    }
    if (filters.projectId != null) {
      addChip('Project', () => update(filters.copyWith(clearProject: true)));
    }
    if (filters.assignedTo != null) {
      addChip('Assignee', () => update(filters.copyWith(clearAssignee: true)));
    }
    if (filters.includeInactive) {
      addChip(
        'Inactive tasks',
        () => update(filters.copyWith(includeInactive: false)),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(spacing: 6, runSpacing: 2, children: chips),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskState state, bool canManage) {
    final visibleTasks = state.filters.includeInactive
        ? state.tasks.where((task) => !task.isActive).toList()
        : state.tasks;

    if (state.status == TaskListStatus.loading && visibleTasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == TaskListStatus.error && visibleTasks.isEmpty) {
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

    if (visibleTasks.isEmpty) {
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerLow
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outlineVariant
                          : const Color(0xFFE2E8F0),
                    ),
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
                            : state.filters.includeInactive
                            ? 'No inactive tasks found'
                            : 'No tasks in your company yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.mode == TaskMode.mine
                            ? 'When someone assigns you a task,\nit will show up here.'
                            : 'Create your first task to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount:
            visibleTasks.length +
            ((state.isLoadingMore || (state.page > 1 && !state.hasMore))
                ? 1
                : 0),
        itemBuilder: (context, i) {
          if (i == visibleTasks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : Text(
                        "You're all caught up",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            );
          }

          final task = visibleTasks[i];
          final taskBloc = context.read<TaskBloc>();
          return Dismissible(
            key: ValueKey('task-swipe-${task.id}-${task.isActive}'),
            direction: canManage
                ? DismissDirection.startToEnd
                : DismissDirection.none,
            background: _SwipeActionBackground(isInactive: !task.isActive),
            confirmDismiss: (_) => _confirmTaskAction(context, task),
            onDismissed: (_) {
              if (task.isActive) {
                taskBloc.add(TaskDeleteRequested(task.id));
              } else {
                taskBloc.add(TaskActivateRequested(task.id));
              }
            },
            child: TaskCard(
              key: ValueKey(
                'task-${task.id}-${task.status}-${task.priority}-${task.title}',
              ),
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
            ),
          );
        },
      ),
    );
  }

  void _showTaskActions(BuildContext context, Task task) {
    final isInactive = !task.isActive;
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            if (isInactive)
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                title: const Text('Activate task'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (!await _confirmTaskAction(context, task)) return;
                  context.read<TaskBloc>().add(TaskActivateRequested(task.id));
                },
              )
            else ...[
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
                title: const Text(
                  'Delete task',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (!await _confirmTaskAction(context, task)) return;
                  context.read<TaskBloc>().add(TaskDeleteRequested(task.id));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmTaskAction(BuildContext context, Task task) async {
    final isActivate = !task.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isActivate ? 'Activate task?' : 'Delete task?'),
        content: Text(
          isActivate
              ? 'This task will be moved back to active tasks.'
              : 'This task will be moved to inactive tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActivate ? 'Activate' : 'Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

class _SwipeActionBackground extends StatelessWidget {
  final bool isInactive;

  const _SwipeActionBackground({required this.isInactive});

  @override
  Widget build(BuildContext context) {
    final color = isInactive ? Colors.green : Colors.red;
    final icon = isInactive ? Icons.check_circle_outline : Icons.delete_outline;
    final label = isInactive ? 'Activate' : 'Delete';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
