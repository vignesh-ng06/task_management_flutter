class User {
  final int id;
  final String email;
  final String? name;
  final String role;
  final int? companyId;
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.companyId,
    this.isActive = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        role: json['role'] ?? 'employee',
        companyId: json['companyId'],
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'companyId': companyId,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  String get displayName =>
      (name?.isNotEmpty == true) ? name! : email;

  String get initials {
    final n = name?.trim();
    if (n == null || n.isEmpty) return email[0].toUpperCase();
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return n[0].toUpperCase();
  }
}