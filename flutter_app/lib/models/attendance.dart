class Attendance {
  final String id;
  final String studentId;
  final String groupId;
  final String subjectId;
  final DateTime date;
  final String status;
  final String updatedBy;
  final DateTime createdAt;
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
