class Student {
  final String id;
  final String fullName;
  final String groupId;
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
