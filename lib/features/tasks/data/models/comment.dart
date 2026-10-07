class Comment {
  final int id;
  final int taskId;
  final int userId;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested user object from backend
  final String authorName;
  final String authorEmail;
  final String authorRole;

  Comment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.authorEmail,
    required this.authorRole,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'],
      taskId: json['taskId'],
      userId: json['userId'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.parse(json['createdAt']),
      authorName: (user?['name'] as String?)?.isNotEmpty == true
          ? user!['name']
          : (user?['email'] as String? ?? 'Unknown'),
      authorEmail: user?['email'] as String? ?? '',
      authorRole: user?['role'] as String? ?? 'employee',
    );
  }

  bool get wasEdited => updatedAt.difference(createdAt).inSeconds > 1;
}