class DashboardStats {
  final int totalTasks;
  final int overdue;
  final int completed;
  final int inProgress;
  final int totalProjects;
  final int totalUsers;

  DashboardStats({
    required this.totalTasks,
    required this.overdue,
    required this.completed,
    required this.inProgress,
    required this.totalProjects,
    required this.totalUsers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalTasks: j['totalTasks'] ?? 0,
        overdue: j['overdue'] ?? 0,
        completed: j['completed'] ?? 0,
        inProgress: j['inProgress'] ?? 0,
        totalProjects: j['totalProjects'] ?? 0,
        totalUsers: j['totalUsers'] ?? 0,
      );
}

class RecentTask {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String projectName;
  final String? assigneeName;

  RecentTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.projectName,
    this.assigneeName,
  });

  factory RecentTask.fromJson(Map<String, dynamic> j) {
    final project = j['project'] as Map<String, dynamic>?;
    final assignee = j['assignee'] as Map<String, dynamic>?;
    return RecentTask(
      id: j['id'],
      title: j['title'],
      status: j['status'],
      priority: j['priority'],
      dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
      projectName: (project?['name'] as String?) ?? 'No project',
      assigneeName: assignee?['name'] as String?,
    );
  }
}

class DashboardData {
  final String scope; // 'company' | 'personal'
  final DashboardStats stats;
  final Map<String, int> statusBreakdown;
  final List<RecentTask> recentTasks;

  DashboardData({
    required this.scope,
    required this.stats,
    required this.statusBreakdown,
    required this.recentTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final breakdown = (j['statusBreakdown'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));

    final tasks = (j['recentTasks'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(RecentTask.fromJson)
        .toList();

    return DashboardData(
      scope: j['scope'] ?? 'personal',
      stats: DashboardStats.fromJson(j['stats'] ?? {}),
      statusBreakdown: breakdown,
      recentTasks: tasks,
    );
  }
}