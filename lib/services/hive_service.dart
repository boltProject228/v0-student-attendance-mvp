import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/attendance.dart';

class HiveService {
  static late Box _box;
  static const String boxName = 'appBox';
  static const int cacheExpirationHours = 24;

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  // Token
  static Future<void> saveToken(String token) async {
    await _box.put('token', token);
  }

  static String? getToken() {
    return _box.get('token');
  }

  static Future<void> removeToken() async {
    await _box.delete('token');
  }

  // User
  static Future<void> saveUser(User user) async {
    await _box.put('user', user);
  }

  static User? getUser() {
    return _box.get('user');
  }

  static Future<void> removeUser() async {
    await _box.delete('user');
  }

  // Groups (List<Group>)
  static Future<void> saveGroups(List<Group> groups) async {
    await _box.put('groups', groups);
    await _updateLastUpdate('groups');
  }

  static List<Group>? getGroups() {
    if (_isCacheValid('groups')) {
      return _box.get('groups')?.cast<Group>();
    }
    return null;
  }

  // Subjects (List<Subject>)
  static Future<void> saveSubjects(List<Subject> subjects) async {
    await _box.put('subjects', subjects);
    await _updateLastUpdate('subjects');
  }

  static List<Subject>? getSubjects() {
    if (_isCacheValid('subjects')) {
      return _box.get('subjects')?.cast<Subject>();
    }
    return null;
  }

  // Students (List<Student>)
  static Future<void> saveStudents(List<Student> students) async {
    await _box.put('students', students);
    await _updateLastUpdate('students');
  }

  static List<Student>? getStudents() {
    if (_isCacheValid('students')) {
      return _box.get('students')?.cast<Student>();
    }
    return null;
  }

  // Attendance (List<Attendance>)
  static Future<void> saveAttendance(List<Attendance> attendance) async {
    await _box.put('attendance', attendance);
    await _updateLastUpdate('attendance');
  }

  static List<Attendance>? getAttendance() {
    if (_isCacheValid('attendance')) {
      return _box.get('attendance')?.cast<Attendance>();
    }
    return null;
  }

  // Общие методы
  static Future<void> clearAll() async {
    await _box.clear();
  }

  static Future<void> _updateLastUpdate(String key) async {
    await _box.put('${key}_lastUpdate', DateTime.now().toIso8601String());
  }

  static bool _isCacheValid(String key) {
    final lastUpdateStr = _box.get('${key}_lastUpdate');
    if (lastUpdateStr == null) return false;
    final lastUpdate = DateTime.parse(lastUpdateStr);
    return DateTime.now().difference(lastUpdate).inHours < cacheExpirationHours;
  }
}