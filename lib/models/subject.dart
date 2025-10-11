import 'package:hive/hive.dart'; // NEW

part 'subject.g.dart'; // NEW

@HiveType(typeId: 3) // NEW
class Subject {
  @HiveField(0) // NEW
  final String id;
  @HiveField(1) // NEW
  final String name;
  @HiveField(2) // NEW
  final String teacherId;
  @HiveField(3) // NEW
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      teacherId: json['teacherId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}