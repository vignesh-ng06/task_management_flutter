import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_header.dart';
import '../../auth/data/user_model.dart';
import '../../projects/data/models/project_ref.dart';
import '../../projects/ui/project_detail_screen.dart';
import '../../tasks/ui/task_detail_screen.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_state.dart';
import '../data/user_details.dart';
import '../data/user_repository.dart';
import 'user_form_sheet.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _userCardColor(BuildContext context) => _isDarkMode(context)
    ? Theme.of(context).colorScheme.surfaceContainerLow
    : Colors.white;

Color _userBorderColor(BuildContext context) => _isDarkMode(context)
    ? Theme.of(context).colorScheme.outlineVariant
    : const Color(0xFFE2E8F0);

Color _userTextColor(BuildContext context) => _isDarkMode(context)
    ? Theme.of(context).colorScheme.onSurface
    : const Color(0xFF0F172A);

Color _userMutedColor(BuildContext context) => _isDarkMode(context)
    ? Theme.of(context).colorScheme.onSurfaceVariant
    : const Color(0xFF64748B);

Color _userAccentColor(BuildContext context) => _isDarkMode(context)
    ? Theme.of(context).colorScheme.primary
    : const Color(0xFF4F46E5);

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<UserDetails> _detailsFuture;
  _AssignedTaskFilter _taskFilter = _AssignedTaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    _detailsFuture = context.read<UserRepository>().getUserDetails(
      widget.user.id,
    );
  }

  Future<void> _refresh() async {
    setState(_loadDetails);
    await _detailsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        User? currentUser;
        for (final item in state.users) {
          if (item.id == widget.user.id) {
            currentUser = item;
            break;
          }
        }
        final isDeactivated =
            currentUser == null && state.successMessage == 'User deactivated';
        final displayedUser = currentUser == null
            ? (isDeactivated
                  ? widget.user.copyWith(isActive: false)
                  : widget.user)
            : User(
                id: currentUser.id,
                email: currentUser.email,
                name: currentUser.name,
                role: currentUser.role,
                companyId: widget.user.companyId,
                companyName: widget.user.companyName,
                industry: widget.user.industry,
                website: widget.user.website,
                companySize: widget.user.companySize,
                isActive: currentUser.isActive,
                createdAt: widget.user.createdAt,
                projects: widget.user.projects,
                projectCount: widget.user.projectCount,
              );

        return Scaffold(
          appBar: AppHeader(
            section: 'User details',
            actions: [
              if (displayedUser.isActive)
                IconButton(
                  tooltip: 'Edit user',
                  onPressed: () =>
                      showUserFormSheet(context, existing: displayedUser),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: FutureBuilder<UserDetails>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load user details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _userMutedColor(context)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final details = snapshot.data!;
              final detailUser = _mergeUser(displayedUser, details.user);
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _IdentityCard(user: detailUser),
                    const SizedBox(height: 16),
                    _TaskOverview(tasks: details.tasksAssigned),
                    const SizedBox(height: 16),
                    _DetailsCard(
                      title: 'Contact',
                      children: [
                        _DetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: detailUser.email,
                        ),
                        if (detailUser.companyName?.isNotEmpty == true)
                          _DetailRow(
                            icon: Icons.business_outlined,
                            label: 'Company',
                            value: detailUser.companyName!,
                          ),
                        if (detailUser.industry?.isNotEmpty == true)
                          _DetailRow(
                            icon: Icons.category_outlined,
                            label: 'Industry',
                            value: detailUser.industry!,
                          ),
                        if (detailUser.website?.isNotEmpty == true)
                          _DetailRow(
                            icon: Icons.language_outlined,
                            label: 'Website',
                            value: detailUser.website!,
                          ),
                        if (detailUser.companySize?.isNotEmpty == true)
                          _DetailRow(
                            icon: Icons.groups_outlined,
                            label: 'Company size',
                            value: detailUser.companySize!,
                          ),
                        if (detailUser.companyId != null)
                          _DetailRow(
                            icon: Icons.tag,
                            label: 'Company ID',
                            value: detailUser.companyId.toString(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProjectsCard(
                      projects: details.projects,
                      projectsCreated: details.projectsCreated,
                      projectCount: detailUser.projectCount,
                    ),
                    const SizedBox(height: 16),
                    _AssignedTasksSection(
                      tasks: details.tasksAssigned,
                      filter: _taskFilter,
                      onFilterChanged: (filter) =>
                          setState(() => _taskFilter = filter),
                      onTaskTap: (task) async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => TaskDetailScreen(taskId: task.id),
                          ),
                        );
                        if (mounted) _refresh();
                      },
                    ),
                    const SizedBox(height: 16),
                    _DetailsCard(
                      title: 'Account',
                      children: [
                        if (detailUser.createdAt != null)
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Joined',
                            value: _formatDate(detailUser.createdAt!),
                          ),
                        if (details.updatedAt != null)
                          _DetailRow(
                            icon: Icons.update_outlined,
                            label: 'Last updated',
                            value: _formatDate(details.updatedAt!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (detailUser.isActive)
                      FilledButton.icon(
                        onPressed: () =>
                            showUserFormSheet(context, existing: detailUser),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit user'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  User _mergeUser(User current, User details) => User(
    id: details.id,
    email: details.email,
    name: details.name,
    role: details.role,
    companyId: current.companyId,
    companyName: current.companyName,
    industry: current.industry,
    website: current.website,
    companySize: current.companySize,
    // The users list is the source of truth for status here. The detail API
    // may omit isActive, which User.fromJson would otherwise default to true.
    isActive: current.isActive,
    createdAt: details.createdAt ?? current.createdAt,
    projects: current.projects,
    projectCount: details.projectCount,
  );

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

enum _AssignedTaskFilter { all, open, overdue }

class _TaskOverview extends StatelessWidget {
  final List<AssignedUserTask> tasks;

  const _TaskOverview({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final openCount = tasks.where((task) => !task.isCompleted).length;
    final overdueCount = tasks.where((task) => task.isOverdue).length;

    return Row(
      children: [
        _OverviewMetric(
          label: 'Assigned',
          value: tasks.length,
          icon: Icons.assignment_outlined,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 8),
        _OverviewMetric(
          label: 'Open',
          value: openCount,
          icon: Icons.radio_button_unchecked,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 8),
        _OverviewMetric(
          label: 'Overdue',
          value: overdueCount,
          icon: Icons.warning_amber_outlined,
          color: overdueCount > 0
              ? const Color(0xFFDC2626)
              : const Color(0xFF64748B),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: _userCardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _userBorderColor(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _userTextColor(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _userMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsCard extends StatelessWidget {
  final List<ProjectRef> projects;
  final List<ProjectRef> projectsCreated;
  final int projectCount;

  const _ProjectsCard({
    required this.projects,
    required this.projectsCreated,
    required this.projectCount,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: 'Projects · $projectCount',
      children: [
        if (projects.isEmpty && projectsCreated.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No projects assigned',
              style: TextStyle(fontSize: 13, color: _userMutedColor(context)),
            ),
          ),
        ...projects.map(
          (project) => _ProjectDetailRow(
            name: project.name,
            label: 'Member',
            projectId: project.id,
          ),
        ),
        ...projectsCreated.map(
          (project) => _ProjectDetailRow(
            name: project.name,
            label: 'Created',
            projectId: project.id,
          ),
        ),
      ],
    );
  }
}

class _ProjectDetailRow extends StatelessWidget {
  final String name;
  final String label;
  final int projectId;

  const _ProjectDetailRow({
    required this.name,
    required this.label,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(
          Icons.folder_open_outlined,
          color: _userMutedColor(context),
        ),
        title: Text(name),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(projectId: projectId),
          ),
        ),
      ),
    );
  }
}

class _AssignedTasksSection extends StatelessWidget {
  final List<AssignedUserTask> tasks;
  final _AssignedTaskFilter filter;
  final ValueChanged<_AssignedTaskFilter> onFilterChanged;
  final ValueChanged<AssignedUserTask> onTaskTap;

  const _AssignedTasksSection({
    required this.tasks,
    required this.filter,
    required this.onFilterChanged,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final openCount = tasks.where((task) => !task.isCompleted).length;
    final overdueCount = tasks.where((task) => task.isOverdue).length;
    final visibleTasks = tasks.where((task) {
      switch (filter) {
        case _AssignedTaskFilter.all:
          return true;
        case _AssignedTaskFilter.open:
          return !task.isCompleted;
        case _AssignedTaskFilter.overdue:
          return task.isOverdue;
      }
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _userCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _userBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned tasks',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _userTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _TaskFilterChip(
                label: 'All ${tasks.length}',
                selected: filter == _AssignedTaskFilter.all,
                onSelected: () => onFilterChanged(_AssignedTaskFilter.all),
              ),
              _TaskFilterChip(
                label: 'Open $openCount',
                selected: filter == _AssignedTaskFilter.open,
                onSelected: () => onFilterChanged(_AssignedTaskFilter.open),
              ),
              _TaskFilterChip(
                label: 'Overdue $overdueCount',
                selected: filter == _AssignedTaskFilter.overdue,
                onSelected: () => onFilterChanged(_AssignedTaskFilter.overdue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  tasks.isEmpty
                      ? 'No tasks assigned'
                      : filter == _AssignedTaskFilter.overdue
                      ? 'No overdue tasks'
                      : 'No open tasks',
                  style: TextStyle(color: _userMutedColor(context)),
                ),
              ),
            )
          else
            ...visibleTasks.map(
              (task) =>
                  _AssignedTaskTile(task: task, onTap: () => onTaskTap(task)),
            ),
        ],
      ),
    );
  }
}

class _TaskFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TaskFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = _isDarkMode(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: _userAccentColor(context).withValues(alpha: 0.2),
      backgroundColor: isDark
          ? colors.surfaceContainerHighest
          : const Color(0xFFF8FAFC),
      side: BorderSide(
        color: selected ? _userAccentColor(context) : _userBorderColor(context),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? _userAccentColor(context) : _userMutedColor(context),
      ),
    );
  }
}

class _AssignedTaskTile extends StatelessWidget {
  final AssignedUserTask task;
  final VoidCallback onTap;

  const _AssignedTaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status.toUpperCase()) {
      'COMPLETED' => const Color(0xFF059669),
      'IN_PROGRESS' => const Color(0xFF3B82F6),
      'REVIEW' => const Color(0xFF7C3AED),
      _ => const Color(0xFF64748B),
    };
    final priorityColor = switch (task.priority.toUpperCase()) {
      'HIGH' => const Color(0xFFDC2626),
      'LOW' => const Color(0xFF64748B),
      _ => const Color(0xFFB45309),
    };

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _userTextColor(context),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TaskBadge(
                text: task.status.replaceAll('_', ' '),
                foreground: statusColor,
                background: statusColor.withValues(alpha: 0.1),
              ),
              _TaskBadge(
                text: task.priority,
                foreground: priorityColor,
                background: priorityColor.withValues(alpha: 0.1),
              ),
              if (task.dueDate != null)
                Text(
                  task.isOverdue
                      ? 'Overdue · ${_formatDueDate(task.dueDate!)}'
                      : 'Due · ${_formatDueDate(task.dueDate!)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: task.isOverdue
                        ? const Color(0xFFDC2626)
                        : _userMutedColor(context),
                  ),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _TaskBadge extends StatelessWidget {
  final String text;
  final Color foreground;
  final Color background;

  const _TaskBadge({
    required this.text,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final User user;

  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final inactive = !user.isActive;
    final accent = _userAccentColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _userCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _userBorderColor(context)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: inactive
                ? _userBorderColor(context)
                : accent.withValues(alpha: 0.16),
            child: Text(
              user.initials,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: inactive ? _userMutedColor(context) : accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: inactive
                  ? _userMutedColor(context)
                  : _userTextColor(context),
              decoration: inactive ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _StatusChip(
                label: user.role.toUpperCase(),
                background: accent.withValues(alpha: 0.16),
                foreground: accent,
              ),
              _StatusChip(
                label: inactive ? 'INACTIVE' : 'ACTIVE',
                background: inactive
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                foreground: inactive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _userCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _userBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _userTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _userMutedColor(context)),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: _userMutedColor(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _userTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
