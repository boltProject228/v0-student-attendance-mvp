import 'package:hive/hive.dart'; // NEW

part 'student.g.dart'; // NEW

@HiveType(typeId: 2) // NEW
class Student {
  @HiveField(0) // NEW
  final String id;
  @HiveField(1) // NEW
  final String fullName;
  @HiveField(2) // NEW
  final String groupId;
  @HiveField(3) // NEW
  final DateTime createdAt;

  Student({
    required this.id,
    required this.fullName,
    required this.groupId,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      groupId: json['groupId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}