import '../models/group.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/attendance.dart';
import '../models/user.dart';

class MockData {
  // Mock login: Returns token and user with settings
  static Map<String, dynamic> mockLogin(String login, String password) {
    Map<String, dynamic> userData;
    if (login == 'teacher' && password == 'pass123') {
      userData = {
        'id': '1',
        'login': 'teacher',
        'role': 'teacher',
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {'theme': 'light', 'language': 'ru', 'notifications': true},
      };
    } else if (login == 'head' && password == 'pass123') {
      userData = {
        'id': '2',
        'login': 'head',
        'role': 'head',
        'createdAt': DateTime.now().toIso8601String(),
        'settings': {'theme': 'dark', 'language': 'ru', 'notifications': false},
      };
    } else {
      throw Exception('Invalid credentials');
    }

    return {
      'token': 'mock_token_$login',
      'user': userData,
    };
  }

  // Mock groups
  static List<Group> mockGetGroups() {
    return [
      Group(
        id: 'g1',
        name: 'Group 101',
        specialty: 'Mathematics',
        course: 1,
        createdAt: DateTime.now(),
      ),
      Group(
        id: 'g2',
        name: 'Group 102',
        specialty: 'Physics',
        course: 2,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Mock students (with groupId references)
  static List<Student> mockGetStudents() {
    return [
      Student(
        id: 's1',
        fullName: 'Ivan Ivanov',
        groupId: 'g1',
        createdAt: DateTime.now(),
      ),
      Student(
        id: 's2',
        fullName: 'Maria Petrova',
        groupId: 'g1',
        createdAt: DateTime.now(),
      ),
      Student(
        id: 's3',
        fullName: 'Alex Sidorov',
        groupId: 'g2',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Mock subjects
  static List<Subject> mockGetSubjects() {
    return [
      Subject(
        id: 'sub1',
        name: 'Algebra',
        teacherId: '1',
        createdAt: DateTime.now(),
      ),
      Subject(
        id: 'sub2',
        name: 'Mechanics',
        teacherId: '1',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Mock attendance
  static List<Attendance> mockGetAttendance() {
    return [
      Attendance(
        id: 'a1',
        studentId: 's1',
        groupId: 'g1',
        subjectId: 'sub1',
        date: DateTime.now(),
        status: 'present',
        updatedBy: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Attendance(
        id: 'a2',
        studentId: 's2',
        groupId: 'g1',
        subjectId: 'sub1',
        date: DateTime.now(),
        status: 'absent',
        updatedBy: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}