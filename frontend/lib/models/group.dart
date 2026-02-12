import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 1)
class Group {
  @HiveField(0)
  final String id; // Custom id, fallback to _id if needed
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String specialty;
  @HiveField(3)
  final int course;
  @HiveField(4)
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.specialty,
    required this.course,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? json['_id']?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      course: (json['course'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Send custom id
      'name': name,
      'specialty': specialty,
      'course': course,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}