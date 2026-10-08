import '../../../tasks/data/models/task_model.dart';

class Project {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int companyId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int taskCount;
  final List<Task> tasks;

  // Nested objects (present when backend includes them)
  final Map<String, dynamic>? creator;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.companyId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.taskCount = 0,
    this.creator,
    this.tasks = const [],
  });

  
factory Project.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    final tasksArray = json['tasks'] as List?;

    int taskCount = 0;
    if (count != null && count['tasks'] != null) {
      taskCount = count['tasks'] as int;
    } else if (tasksArray != null) {
      taskCount = tasksArray.length;
    }

    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      companyId: json['companyId'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      taskCount: taskCount,
      creator: json['creator'] as Map<String, dynamic>?,
      tasks: (tasksArray ?? [])
          .cast<Map<String, dynamic>>()
          .where((t) => t['isActive'] != false)
          .map(Task.fromJson)
          .toList(),
    );
  }

  String get creatorName =>
      (creator?['name'] as String?) ?? 'Unknown';

  String get createdDateLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

Project copyWith({
  String? name,
  String? description,
  bool? isActive,
  int? taskCount,
  List<Task>? tasks,
}) {
  return Project(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    companyId: companyId,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
    taskCount: taskCount ?? this.taskCount,
    creator: creator,
    tasks: tasks ?? this.tasks,
  );
}
}

class ProjectDetail {
  final Project project;
  final List<Map<String, dynamic>> tasks; // raw task JSON

  ProjectDetail({required this.project, required this.tasks});

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    return ProjectDetail(
      project: Project.fromJson(json),
      tasks: tasks,
    );
  }
}