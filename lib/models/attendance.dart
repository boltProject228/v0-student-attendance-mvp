import 'package:hive/hive.dart'; // NEW

part 'attendance.g.dart'; // NEW

@HiveType(typeId: 4) // NEW
class Attendance {
  @HiveField(0) // NEW
  final String id;
  @HiveField(1) // NEW
  final String studentId;
  @HiveField(2) // NEW
  final String groupId;
  @HiveField(3) // NEW
  final String subjectId;
  @HiveField(4) // NEW
  final DateTime date;
  @HiveField(5) // NEW
  final String status;
  @HiveField(6) // NEW
  final String updatedBy;
  @HiveField(7) // NEW
  final DateTime createdAt;
  @HiveField(8) // NEW
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.subjectId,
    required this.date,
    required this.status,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      groupId: json['groupId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      status: json['status'] ?? 'present',
      updatedBy: json['updatedBy'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'groupId': groupId,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'status': status,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isSick => status == 'sick';
  bool get isWsk => status == 'wsk';
}