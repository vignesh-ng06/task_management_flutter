import 'package:task_app/features/projects/data/models/project_ref.dart';

class User {
  final int id;
  final String email;
  final String? name;
  final String role;
  final int? companyId;
  final String? companyName;
  final String? industry;
  final String? website;
  final String? companySize;
  final bool isActive;
  final DateTime? createdAt;
  final List<ProjectRef> projects;
  final int projectCount;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.companyId,
    this.companyName,
    this.industry,
    this.website,
    this.companySize,
    this.isActive = true,
    this.createdAt,
    this.projects = const [],
    this.projectCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'] ?? 'employee',
      companyId: json['companyId'],
      companyName: company is Map<String, dynamic>
          ? company['name'] as String?
          : json['companyName'] as String?,
      industry: company is Map<String, dynamic>
          ? company['industry'] as String?
          : json['industry'] as String?,
      website: company is Map<String, dynamic>
          ? company['website'] as String?
          : json['website'] as String?,
      companySize: company is Map<String, dynamic>
          ? company['companySize'] as String?
          : json['companySize'] as String?,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      projects: (json['projects'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProjectRef.fromJson)
          .toList(),
      projectCount: (json['projectCount'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'companyId': companyId,
    'website': website,
    'companySize': companySize,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'projects': projects.map((p) => p.toJson()).toList(),
    'projectCount': projectCount,
  };

  User copyWith({
    String? name,
    String? role,
    bool? isActive,
    List<ProjectRef>? projects,
    int? projectCount,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId,
      companyName: companyName,
      industry: industry,
      website: website,
      companySize: companySize,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      projects: projects ?? this.projects,
      projectCount: projectCount ?? this.projectCount,
    );
  }

  String get displayName => (name?.isNotEmpty == true) ? name! : email;

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
