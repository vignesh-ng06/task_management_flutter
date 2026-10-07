class Task {
  final int id;
  final String title;
  final String? description;
  final String status;         // TODO | IN_PROGRESS | REVIEW | COMPLETED
  final String priority;       // HIGH | MEDIUM | LOW
  final int priorityLevel;     // 1 | 2 | 3
  final DateTime? dueDate;
  final int? assignedTo;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional nested fields (present when backend includes them)
  final Map<String, dynamic>? assignee;
  final Map<String, dynamic>? creator;
  final Map<String, dynamic>? project;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.priorityLevel,
    this.dueDate,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.assignee,
    this.creator,
    this.project,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      priorityLevel: json['priorityLevel'] ?? 2,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assignedTo: json['assignedTo'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      assignee: json['assignee'] as Map<String, dynamic>?,
      creator: json['creator'] as Map<String, dynamic>?,
      project: json['project'] as Map<String, dynamic>?,
    );
  }

  // UI helpers
  String get projectName => (project?['name'] as String?) ?? 'No project';
  String get assigneeName => (assignee?['name'] as String?) ?? 'Unassigned';

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'COMPLETED';

  String get dueDateLabel {
    if (dueDate == null) return 'No due date';
    final d = dueDate!;
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue by ${-diff}d';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}