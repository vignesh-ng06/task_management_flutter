class ProjectRef {
  final int id;
  final String name;

  ProjectRef({required this.id, required this.name});

  factory ProjectRef.fromJson(Map<String, dynamic> j) => ProjectRef(
        id: j['id'],
        name: j['name'] ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}