class TaskActivity {
  final int id;
  final int taskId;
  final int userId;
  final String type;    // CREATED | STATUS_CHANGED | UPDATED | COMMENTED
  final String message;
  final DateTime createdAt;
  final String actorName;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.actorName,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String?;
    return TaskActivity(
      id: j['id'],
      taskId: j['taskId'],
      userId: j['userId'],
      type: j['type'],
      message: j['message'],
      createdAt: DateTime.parse(j['createdAt']),
      actorName: (name != null && name.isNotEmpty)
          ? name
          : (user?['email'] as String? ?? 'Someone'),
    );
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return createdAt.toLocal().toString().split(' ')[0];
  }
}