class User {
  final int id;
  final String email;
  final String? name;
  final String role;
  final int companyId;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.companyId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        role: json['role'],
        companyId: json['companyId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'companyId': companyId,
      };
}