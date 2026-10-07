class AppNotification {
  final int id;
  final int userId;
  final String type;      // TASK_ASSIGNED | COMMENT_ADDED | STATUS_CHANGED
  final String title;
  final String message;
  final String? linkType; // "task" | "project"
  final int? linkId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.linkType,
    this.linkId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      linkType: json['linkType'],
      linkId: json['linkId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      linkType: linkType,
      linkId: linkId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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