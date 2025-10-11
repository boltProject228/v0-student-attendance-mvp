class Group {
  final String id;
  final String name;
  final String specialty;
  final int course;
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
