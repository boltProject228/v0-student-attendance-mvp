import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 4)
class Attendance {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final String groupId;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String status;
  @HiveField(5)
  final String updatedBy;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.groupId,
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
      'date': date.toIso8601String(),
      'status': status,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Attendance copyWith({
    String? status,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id,
      studentId: studentId,
      groupId: groupId,
      date: date,
      status: status ?? this.status,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isSick => status == 'sick';
  bool get isWsk => status == 'wsk';
}