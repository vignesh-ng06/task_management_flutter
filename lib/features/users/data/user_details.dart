import '../../auth/data/user_model.dart';
import '../../projects/data/models/project_ref.dart';

class UserDetails {
  final User user;
  final DateTime? updatedAt;
  final List<ProjectRef> projects;
  final List<ProjectRef> projectsCreated;
  final List<AssignedUserTask> tasksAssigned;

  const UserDetails({
    required this.user,
    this.updatedAt,
    this.projects = const [],
    this.projectsCreated = const [],
    this.tasksAssigned = const [],
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    return UserDetails(
      user: user,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      projects: _readProjects(json['projects']),
      projectsCreated: _readProjects(json['projectsCreated']),
      tasksAssigned: (json['tasksAssigned'] as List? ?? const [])
          .map(
            (task) => AssignedUserTask.fromJson(
              Map<String, dynamic>.from(task as Map),
            ),
          )
          .toList(),
    );
  }

  static List<ProjectRef> _readProjects(dynamic value) {
    return (value as List? ?? const [])
        .map(
          (project) => ProjectRef.fromJson(
            Map<String, dynamic>.from(project as Map),
          ),
        )
        .toList();
  }
}

class AssignedUserTask {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;

  const AssignedUserTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
  });

  factory AssignedUserTask.fromJson(Map<String, dynamic> json) {
    return AssignedUserTask(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'TODO',
      priority: json['priority'] as String? ?? 'MEDIUM',
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );
  }

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
}
