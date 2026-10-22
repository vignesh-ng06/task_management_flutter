import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../tasks/bloc/task_bloc.dart';
import '../../tasks/bloc/task_event.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/bloc/task_state.dart';
import '../../tasks/ui/task_detail_screen.dart';
import '../../tasks/ui/task_form_sheet.dart';
import '../../tasks/ui/widgets/task_card.dart';
import '../data/models/project.dart';
import '../data/project_repository.dart';
import 'project_members_sheet.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<Project> _future;
  final _scrollController = ScrollController();
  final _taskSearchController = TextEditingController();
  List<Task> _tasks = const [];
  bool _tasksLoading = false;
  bool _loadingMore = false;
  bool _hasMoreTasks = true;
  int _taskPage = 1;
  late TaskFilters _taskFilters;

  static const _taskPageSize = 20;

  @override
  void initState() {
    super.initState();
    _taskFilters = TaskFilters(projectId: widget.projectId);
    _load();
    _scrollController.addListener(_loadMoreWhenNeeded);
    _loadTasks(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  void _load() {
    _future = context.read<ProjectRepository>().getProject(widget.projectId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_future, _loadTasks(reset: true)]);
  }

  Future<void> _loadTasks({required bool reset}) async {
    if (_tasksLoading || _loadingMore || (!reset && !_hasMoreTasks)) return;

    if (reset) {
      _taskPage = 1;
      _hasMoreTasks = true;
      if (mounted) setState(() => _tasks = const []);
      _tasksLoading = true;
    } else {
      _loadingMore = true;
    }

    try {
      final page = await context.read<TaskRepository>().listTasks(
        filters: _taskFilters,
        page: _taskPage,
        limit: _taskPageSize,
      );
      if (!mounted) return;
      setState(() {
        _tasks = reset ? page : [..._tasks, ...page];
        _hasMoreTasks = page.length == _taskPageSize;
        if (page.isNotEmpty) _taskPage++;
      });
    } finally {
      _tasksLoading = false;
      _loadingMore = false;
    }
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.position.extentAfter < 500) {
      _loadTasks(reset: false);
    }
  }

  Future<void> _openTaskFilters() async {
    final filters = await showModalBottomSheet<TaskFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectTaskFilterSheet(initialFilters: _taskFilters),
    );
    if (!mounted || filters == null) return;
    setState(() => _taskFilters = filters);
    _loadTasks(reset: true);
  }

  int _activeTaskFilterCount() {
    var count = 0;
    if (_taskFilters.status != null) count++;
    if (_taskFilters.priority != null) count++;
    if (_taskFilters.includeInactive) count++;
    if (_taskFilters.search.isNotEmpty) count++;
    return count;
  }

  Widget _buildAppliedTaskFilters() {
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

    if (_taskFilters.search.isNotEmpty) {
      addChip('Search: ${_taskFilters.search}', () {
        _taskSearchController.clear();
        setState(() => _taskFilters = _taskFilters.copyWith(search: ''));
        _loadTasks(reset: true);
      });
    }
    if (_taskFilters.status != null) {
      addChip(_taskFilters.status!, () {
        setState(() => _taskFilters = _taskFilters.copyWith(clearStatus: true));
        _loadTasks(reset: true);
      });
    }
    if (_taskFilters.priority != null) {
      addChip(_taskFilters.priority!, () {
        setState(
          () => _taskFilters = _taskFilters.copyWith(clearPriority: true),
        );
        _loadTasks(reset: true);
      });
    }
    if (_taskFilters.includeInactive) {
      addChip('Inactive tasks', () {
        setState(
          () => _taskFilters = _taskFilters.copyWith(includeInactive: false),
        );
        _loadTasks(reset: true);
      });
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(spacing: 6, runSpacing: 2, children: chips),
      ),
    );
  }

  Future<void> _createTask(BuildContext context, {int? projectId}) async {
    final saved = await showTaskFormSheet(context, projectId: projectId);
    if (!context.mounted || !saved) return;

    context.read<TaskBloc>().add(const TasksRefreshRequested());
    showSuccessSnackBar(
      context,
      'Task created',
      backgroundColor: const Color(0xFF10B981),
    );
    await _refresh();
  }

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(section: 'Project details'),
      floatingActionButton: _canManage(context)
          ? FloatingActionButton.extended(
              heroTag: 'project-detail-new-task',
              onPressed: () =>
                  _createTask(context, projectId: widget.projectId),
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
          final tasks = _taskFilters.includeInactive
              ? _tasks.where((task) => !task.isActive).toList()
              : _tasks;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              controller: _scrollController,
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

                // TODO: wire to backend when goal, links, and files are available on Project.
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
                      _taskFilters.includeInactive
                          ? 'Inactive tasks (${tasks.length})'
                          : 'Tasks (${tasks.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildAppliedTaskFilters(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search tasks…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _taskFilters.search.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _taskSearchController.clear();
                                    setState(
                                      () => _taskFilters = _taskFilters
                                          .copyWith(search: ''),
                                    );
                                    _loadTasks(reset: true);
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          setState(
                            () => _taskFilters = _taskFilters.copyWith(
                              search: value.trim(),
                            ),
                          );
                          _loadTasks(reset: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton.filledTonal(
                          onPressed: _openTaskFilters,
                          icon: const Icon(Icons.tune, size: 20),
                          tooltip: 'Filters',
                        ),
                        if (_activeTaskFilterCount() > 0)
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
                                '${_activeTaskFilterCount()}',
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
                const SizedBox(height: 12),
                if (_tasksLoading && tasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: double.infinity,
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
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 56,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _taskFilters.includeInactive
                                  ? 'No inactive tasks in this project'
                                  : 'No tasks yet in this project',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Break this project into small tasks.\nEach task = one clear action.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (_canManage(context)) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    _createTask(context, projectId: project.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add first task'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  ...tasks.map((task) {
                    final card = TaskCard(
                      task: task,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: task.id),
                          ),
                        ).then((_) => _refresh());
                      },
                      onLongPress: _canManage(context)
                          ? () => _showTaskActions(context, task)
                          : null,
                    );

                    if (!_canManage(context)) return card;

                    return Dismissible(
                      key: ValueKey(
                        'proj-task-${task.id}-${task.status}-${task.priority}',
                      ),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) => task.isActive
                          ? _confirmAndDeleteTask(task)
                          : _confirmAndActivateTask(task),
                      background: _SwipeActionBackground(
                        isInactive: !task.isActive,
                      ),
                      child: card,
                    );
                  }),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_hasMoreTasks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No more tasks',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ],
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
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmAndActivateTask(task);
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit task'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final saved = await showTaskFormSheet(
                    context,
                    existing: task,
                  );
                  if (!context.mounted || !saved) return;
                  await _refresh();
                  if (!context.mounted) return;
                  showSuccessSnackBar(
                    context,
                    'Task updated',
                    backgroundColor: const Color(0xFF3B82F6),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete task',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmAndDeleteTask(task);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmAndActivateTask(Task task) async {
    final confirmed = await _showTaskConfirmation(
      title: 'Activate task?',
      message: 'This task will be moved back to your active tasks.',
      actionLabel: 'Activate',
      actionColor: Colors.green,
    );
    if (!confirmed || !mounted) return false;

    try {
      await context.read<TaskRepository>().activateTask(task.id);
      if (!mounted) return false;
      setState(
        () => _tasks = _tasks.where((item) => item.id != task.id).toList(),
      );
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }

  Future<bool> _confirmAndDeleteTask(Task task) async {
    final confirmed = await _showTaskConfirmation(
      title: 'Delete task?',
      message: 'This task will be moved to inactive tasks.',
      actionLabel: 'Delete',
      actionColor: Colors.red,
    );
    if (!confirmed || !mounted) return false;

    try {
      await context.read<TaskRepository>().deleteTask(task.id);
      if (!mounted) return false;
      setState(
        () => _tasks = _tasks.where((item) => item.id != task.id).toList(),
      );
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }

  Future<bool> _showTaskConfirmation({
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(actionLabel, style: TextStyle(color: actionColor)),
              ),
            ],
          ),
        ) ??
        false;
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

class _ProjectTaskFilterSheet extends StatefulWidget {
  final TaskFilters initialFilters;

  const _ProjectTaskFilterSheet({required this.initialFilters});

  @override
  State<_ProjectTaskFilterSheet> createState() =>
      _ProjectTaskFilterSheetState();
}

class _ProjectTaskFilterSheetState extends State<_ProjectTaskFilterSheet> {
  late TaskFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Filter tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(
                    () => _filters = TaskFilters(projectId: _filters.projectId),
                  ),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['TODO', 'IN_PROGRESS', 'REVIEW', 'COMPLETED']
                  .map(
                    (status) => ChoiceChip(
                      label: Text(status),
                      selected: _filters.status == status,
                      onSelected: (selected) => setState(
                        () => _filters = selected
                            ? _filters.copyWith(status: status)
                            : _filters.copyWith(clearStatus: true),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['HIGH', 'MEDIUM', 'LOW']
                  .map(
                    (priority) => ChoiceChip(
                      label: Text(priority),
                      selected: _filters.priority == priority,
                      onSelected: (selected) => setState(
                        () => _filters = selected
                            ? _filters.copyWith(priority: priority)
                            : _filters.copyWith(clearPriority: true),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Task visibility',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Active tasks'),
                  selected: !_filters.includeInactive,
                  onSelected: (_) => setState(
                    () => _filters = _filters.copyWith(includeInactive: false),
                  ),
                ),
                ChoiceChip(
                  label: const Text('Inactive tasks'),
                  selected: _filters.includeInactive,
                  onSelected: (selected) => setState(
                    () =>
                        _filters = _filters.copyWith(includeInactive: selected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, _filters),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: colors.primary,
              ),
              child: const Text('Apply filters'),
            ),
          ],
        ),
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const Icon(Icons.group_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '${members.length} ${members.length == 1 ? 'member' : 'members'}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        // Avatar stack
        if (members.isNotEmpty)
          SizedBox(
            height: 28,
            width: (members.length > 4 ? 4 : members.length) * 22.0 + 8,
            child: Stack(
              children: List.generate(members.length > 4 ? 4 : members.length, (
                i,
              ) {
                final u = members[i];
                return Positioned(
                  left: i * 20.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark ? colors.surface : Colors.white,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: isDark
                          ? colors.primaryContainer
                          : Colors.indigo.shade50,
                      child: Text(
                        u.initials,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? colors.onPrimaryContainer
                              : Colors.indigo.shade900,
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
