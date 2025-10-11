class Subject {
  final String id;
  final String name;
  final String teacherId;
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
