import 'package:attendance_system/models/group.dart';
import 'package:attendance_system/models/student.dart';

String normalize(String input) {
  String normalized = input.toUpperCase();
  const map = {
    'Қ': 'К',
    'Ә': 'А',
    'Ө': 'О',
    'Ұ': 'У',
    'Ғ': 'Г',
    'Ң': 'Н',
    'І': 'И',
  };
  map.forEach((key, value) {
    normalized = normalized.replaceAll(key, value);
  });
  return normalized.trim();
}

List<Group> filterGroups(
  List<Map<String, dynamic>> analytics,
  List<Group> allGroups,
  List<Student> students,
  String searchQuery,
  String selectedSpecialty,
  String selectedCourse,
) {
  final normalizedQuery = normalize(searchQuery);
  final filteredAnalytics = analytics.where((data) {
    final groupName = normalize(data['name']);
    final specialty = normalize(data['specialty']);
    final courseStr = data['course'].toString();

    final matchesSearch = groupName.contains(normalizedQuery) ||
        students.any((s) => s.groupId == data['groupId'] && normalize(s.fullName).contains(normalizedQuery));
    final matchesCourse = selectedCourse == 'Все' || courseStr == selectedCourse;
    final matchesSpecialty = selectedSpecialty == 'Все' || specialty.contains(normalize(selectedSpecialty));

    return matchesSearch && matchesCourse && matchesSpecialty;
  }).map((data) => data['groupId']).toSet();

  return allGroups.where((group) => filteredAnalytics.contains(group.id)).toList();
}

List<Map<String, dynamic>> filterStudents(
  List<Map<String, dynamic>> analytics,
  List<Student> students,
  List<Group> groups,
  String searchQuery,
  String selectedSpecialty,
  String selectedCourse,
  String selectedGroupChip,
) {
  final normalizedQuery = normalize(searchQuery);
  return analytics.where((data) {
    final fullName = normalize(data['fullName']);
    final matchesSearch = fullName.contains(normalizedQuery);
    final matchesGroup = selectedGroupChip.isEmpty || data['groupId'] == selectedGroupChip;
    final studentGroup = groups.firstWhere(
      (g) => g.id == data['groupId'],
      orElse: () => Group(id: '', name: '', specialty: '', course: 0, createdAt: DateTime.now()),
    );
    final specialty = normalize(studentGroup.specialty);
    final courseStr = studentGroup.course.toString();
    final matchesCourse = selectedCourse == 'Все' || courseStr == selectedCourse;
    final matchesSpecialty = selectedSpecialty == 'Все' || specialty.contains(normalize(selectedSpecialty));

    return matchesSearch && matchesGroup && matchesCourse && matchesSpecialty;
  }).toList();
}