import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../tasks/ui/task_detail_screen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../data/models/dashboard_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(context.read())..add(HomeLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<HomeBloc>().add(HomeRefreshRequested()),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HomeStatus.error && state.data == null) {
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
                        .read<HomeBloc>()
                        .add(HomeLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(HomeRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _GreetingCard(scope: data.scope),
                const SizedBox(height: 16),
                _StatsGrid(stats: data.stats, scope: data.scope),
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Recent tasks',
                  icon: Icons.history,
                ),
                const SizedBox(height: 12),
                if (data.recentTasks.isEmpty)
                  _EmptyCard(
                    message: 'No tasks yet',
                    hint: 'Create your first task to get started',
                  )
                else
                  ...data.recentTasks.map((t) => _RecentTaskTile(task: t)),
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Status breakdown',
                  icon: Icons.donut_large,
                ),
                const SizedBox(height: 12),
                _StatusBreakdown(breakdown: data.statusBreakdown),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// Greeting card
// ─────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final String scope;
  const _GreetingCard({required this.scope});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final name = user?.name ?? user?.email ?? 'User';
    final isCompanyScope = scope == 'company';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(label: (user?.role ?? '').toUpperCase()),
              const SizedBox(width: 8),
              _Pill(
                label: isCompanyScope ? 'COMPANY VIEW' : 'MY TASKS',
                outline: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool outline;
  const _Pill({required this.label, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : Colors.white.withOpacity(0.2),
        border: outline
            ? Border.all(color: Colors.white.withOpacity(0.5))
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Stats grid
// ─────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final String scope;
  const _StatsGrid({required this.stats, required this.scope});

  @override
  Widget build(BuildContext context) {
    final isCompany = scope == 'company';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: isCompany ? 'Total tasks' : 'My tasks',
          value: stats.totalTasks,
          icon: Icons.check_circle_outline,
          color: const Color(0xFF4F46E5),
        ),
        _StatCard(
          label: 'Overdue',
          value: stats.overdue,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFDC2626),
        ),
        _StatCard(
          label: 'Completed',
          value: stats.completed,
          icon: Icons.done_all,
          color: const Color(0xFF10B981),
        ),
        _StatCard(
          label: 'In progress',
          value: stats.inProgress,
          icon: Icons.autorenew,
          color: const Color(0xFF3B82F6),
        ),
        if (isCompany)
          _StatCard(
            label: 'Projects',
            value: stats.totalProjects,
            icon: Icons.folder_outlined,
            color: const Color(0xFF8B5CF6),
          ),
        if (isCompany)
          _StatCard(
            label: 'Team members',
            value: stats.totalUsers,
            icon: Icons.groups_outlined,
            color: const Color(0xFF0EA5E9),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Section header
// ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Recent task tile
// ─────────────────────────────────────────
class _RecentTaskTile extends StatelessWidget {
  final RecentTask task;
  const _RecentTaskTile({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case 'HIGH':
        return const Color(0xFFDC2626);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.status.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Status breakdown bars
// ─────────────────────────────────────────
class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> breakdown;
  const _StatusBreakdown({required this.breakdown});

  Color _colorFor(String status) {
    switch (status) {
      case 'TODO':
        return const Color(0xFF64748B);
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      case 'REVIEW':
        return const Color(0xFF8B5CF6);
      case 'COMPLETED':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return const _EmptyCard(
        message: 'No tasks',
        hint: 'Stats will appear once you create tasks',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: breakdown.entries.map((e) {
          final pct = total == 0 ? 0.0 : e.value / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_colorFor(e.key)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty card
// ─────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  final String hint;
  const _EmptyCard({required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}