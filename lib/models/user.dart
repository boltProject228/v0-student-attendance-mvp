import 'package:hive/hive.dart'; // NEW

part 'user.g.dart'; // NEW: Generated file

@HiveType(typeId: 0) // NEW
class User {
  @HiveField(0) // NEW
  final String id;
  @HiveField(1) // NEW
  final String login;
  @HiveField(2) // NEW
  final String role;
  @HiveField(3) // NEW
  final DateTime createdAt;

  User({
    required this.id,
    required this.login,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      login: json['login'] ?? '',
      role: json['role'] ?? 'teacher',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'login': login,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isHead => role == 'head';
  bool get isTeacher => role == 'teacher';
}