import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 2)
class Student {
  @HiveField(0)
  final String id; // Will use _id or id from JSON
  @HiveField(1)
  final String fullName;
  @HiveField(2)
  final String groupId;
  @HiveField(3)
  final DateTime createdAt;

  Student({
    required this.id,
    required this.fullName,
    required this.groupId,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: (json['_id'] ?? json['id']) as String? ?? '', // Handle both _id and id
      fullName: json['fullName'] ?? '',
      groupId: json['groupId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // Send _id to server
      'fullName': fullName,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}