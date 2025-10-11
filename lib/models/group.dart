import 'package:hive/hive.dart'; // NEW

part 'group.g.dart'; // NEW

@HiveType(typeId: 1) // NEW
class Group {
  @HiveField(0) // NEW
  final String id;
  @HiveField(1) // NEW
  final String name;
  @HiveField(2) // NEW
  final String specialty;
  @HiveField(3) // NEW
  final int course;
  @HiveField(4) // NEW
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
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      course: json['course'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'specialty': specialty,
      'course': course,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}