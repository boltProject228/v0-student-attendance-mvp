import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String login;
  @HiveField(2)
  final String role;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4) // NEW: Settings
  final Map<String, dynamic>? settings;
  @HiveField(5)
  final String? firstName;
  @HiveField(6)
  final String? lastName;

  User({
    required this.id,
    required this.login,
    required this.role,
    required this.createdAt,
    this.settings,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      login: json['login'] ?? '',
      role: json['role'] ?? 'teacher',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      settings: json['settings'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'login': login,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  bool get isHead => role == 'head';
  bool get isTeacher => role == 'teacher';

  String get fullName => '${lastName ?? ''} ${firstName ?? ''}'.trim();
}