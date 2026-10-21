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

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();

  bool _canManage(BuildContext context) {
    final role = context.watch<AuthBloc>().state.user?.role;
    return role == 'admin' || role == 'manager';
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
                    onPressed: () => context.read<ProjectBloc>().add(
                      const ProjectsLoadRequested(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state.projects.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProjectBloc>().add(const ProjectsLoadRequested());
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProjectBloc>().add(const ProjectsLoadRequested());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: state.projects.length,
              itemBuilder: (_, i) {
                final project = state.projects[i];
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
                        builder: (_) =>
                            ProjectDetailScreen(projectId: project.id),
                      ),
                    );
                    projectBloc.add(const ProjectsLoadRequested());
                  },
                  onLongPress: _canManage(context)
                      ? () => _showActions(context, project)
                      : null,
                );
              },
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
