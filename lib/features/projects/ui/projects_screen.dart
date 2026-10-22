import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../data/models/project.dart';
import 'project_detail_screen.dart';
import 'project_form_sheet.dart';
import 'widgets/project_card_skeleton.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const ProjectsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const _ProjectsView();
  }
}

enum _ProjectFilter { all, active, inactive, withTasks, withoutTasks }

class _ProjectsView extends StatefulWidget {
  const _ProjectsView();

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _ProjectFilter _filter = _ProjectFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
  }

  void _requestProjectsLoad(BuildContext context) {
    context.read<ProjectBloc>().add(
      ProjectsLoadRequested(
        includeInactive: _filter == _ProjectFilter.inactive,
      ),
    );
  }

  void _onFilterChanged(BuildContext context, _ProjectFilter filter) {
    setState(() => _filter = filter);
    _requestProjectsLoad(context);
  }

  List<Project> _visibleProjects(List<Project> projects) {
    final query = _searchQuery.trim().toLowerCase();
    return projects.where((project) {
      final matchesSearch =
          query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          (project.description?.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;

      return switch (_filter) {
        _ProjectFilter.all => true,
        _ProjectFilter.active => project.isActive,
        _ProjectFilter.inactive => !project.isActive,
        _ProjectFilter.withTasks => project.taskCount > 0,
        _ProjectFilter.withoutTasks => project.taskCount == 0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(section: 'Projects'),
      floatingActionButton: _canManage(context)
          ? FloatingActionButton.extended(
              heroTag: 'projects-new-project',
              onPressed: () => showProjectFormSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('New project'),
            )
          : null,
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.successMessage != null) {
            final isUpdate = state.successMessage == 'Project updated';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: isUpdate
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProjectListStatus.loading &&
              state.projects.isEmpty) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: 4,
              itemBuilder: (_, _) => const ProjectCardSkeleton(),
            );
          }
          if (state.status == ProjectListStatus.error &&
              state.projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.error ?? 'Error loading projects'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _requestProjectsLoad(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state.projects.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                _requestProjectsLoad(context);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.outlineVariant
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_outlined,
                              size: 56,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No projects yet',
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
                              'Projects group related tasks together.\nStart with one — like "Marketing Q4".',
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
                                onPressed: () => showProjectFormSheet(context),
                                icon: const Icon(Icons.add),
                                label: const Text('New project'),
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

          final visibleProjects = _visibleProjects(state.projects);

          return RefreshIndicator(
            onRefresh: () async {
              _requestProjectsLoad(context);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Column(
              children: [
                _ProjectSearchBar(
                  controller: _searchController,
                  query: _searchQuery,
                  filter: _filter,
                  onQueryChanged: (value) => setState(() {
                    _searchQuery = value;
                  }),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  onFilterChanged: (value) => _onFilterChanged(context, value),
                ),
                Expanded(
                  child: visibleProjects.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _NoMatchingProjects(
                            hasSearch: _searchQuery.trim().isNotEmpty,
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filter = _ProjectFilter.all;
                              });
                            },
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                          itemCount: visibleProjects.length,
                          itemBuilder: (_, i) {
                            final project = visibleProjects[i];
                            final projectBloc = context.read<ProjectBloc>();
                            return _ProjectCard(
                              key: ValueKey(
                                'proj-${project.id}-${project.name}-${project.description}',
                              ),
                              project: project,
                              onTap: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProjectDetailScreen(
                                      projectId: project.id,
                                    ),
                                  ),
                                );
                                projectBloc.add(
                                  ProjectsLoadRequested(
                                    includeInactive:
                                        _filter == _ProjectFilter.inactive,
                                  ),
                                );
                              },
                              onLongPress: _canManage(context)
                                  ? () => _showActions(context, project)
                                  : null,
                            );
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

  void _showActions(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit project'),
              onTap: () {
                Navigator.pop(sheetCtx);
                showProjectFormSheet(context, existing: project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete project',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDelete(context, project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          '"${project.name}" will be moved to inactive. Tasks will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ProjectBloc>().add(
                ProjectDeleteRequested(project.id),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProjectSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _ProjectFilter filter;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_ProjectFilter> onFilterChanged;

  const _ProjectSearchBar({
    required this.controller,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onClear,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search projects or descriptions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_ProjectFilter>(
            tooltip: 'Filter projects',
            initialValue: filter,
            onSelected: onFilterChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProjectFilter.all,
                child: Text('All projects'),
              ),
              PopupMenuItem(
                value: _ProjectFilter.active,
                child: Text('Active projects'),
              ),
              PopupMenuItem(
                value: _ProjectFilter.inactive,
                child: Text('Inactive projects'),
              ),
              PopupMenuItem(
                value: _ProjectFilter.withTasks,
                child: Text('Projects with tasks'),
              ),
              PopupMenuItem(
                value: _ProjectFilter.withoutTasks,
                child: Text('Projects without tasks'),
              ),
            ],
            icon: Badge(
              isLabelVisible: filter != _ProjectFilter.all,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingProjects extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onClear;

  const _NoMatchingProjects({required this.hasSearch, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.filter_alt_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'No matching projects'
                  : 'No projects for this filter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different name or description.'
                  : 'Try another filter to see more projects.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? colors.surfaceContainerLow : Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.indigo, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                project.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (project.description != null &&
                  project.description!.isNotEmpty)
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? colors.onSurfaceVariant : Colors.grey[600],
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${project.taskCount} tasks',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? colors.onSurfaceVariant
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    project.createdDateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? colors.onSurfaceVariant
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
