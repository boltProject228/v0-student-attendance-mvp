import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/attendance.dart';

class HiveService {
  static Box? _box;
  static const String boxName = 'appBox';
  static const int cacheExpirationHours = 24;

  static Future<void> init() async {
    await Hive.initFlutter();
    print('Hive initialized');
    _box = await Hive.openBox(boxName);
    print('Box opened: $boxName');
  }

  static Future<void> _ensureBoxInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }

  // Token
  static Future<void> saveToken(String token) async {
    await _ensureBoxInitialized();
    await _box!.put('token', token);
    print('Token saved: $token');
  }

  static String? getToken() {
    if (_box == null || !_box!.isOpen) return null;
    return _box!.get('token');
  }

  static Future<void> removeToken() async {
    await _ensureBoxInitialized();
    await _box!.delete('token');
    print('Token removed');
  }

  // User
  static Future<void> saveUser(User user) async {
    await _ensureBoxInitialized();
    await _box!.put('user', user);
    print('User saved: ${user.login}');
  }

  static User? getUser() {
    if (_box == null || !_box!.isOpen) return null;
    return _box!.get('user');
  }

  static Future<void> removeUser() async {
    await _ensureBoxInitialized();
    await _box!.delete('user');
    print('User removed');
  }

  // Groups (List<Group>)
  static Future<void> saveGroups(List<Group> groups) async {
    await _ensureBoxInitialized();
    print('Saving groups: ${groups.length} items');
    await _box!.put('groups', groups);
    await _updateLastUpdate('groups');
    print('Groups saved');
  }

  static List<Group>? getGroups() {
    if (_box == null || !_box!.isOpen) return null;
    if (_isCacheValid('groups')) {
      return _box!.get('groups')?.cast<Group>();
    }
    return null;
  }

  

  // Students (List<Student>)
  static Future<void> saveStudents(List<Student> students) async {
    await _ensureBoxInitialized();
    print('Saving students: ${students.length} items');
    try {
      await _box!.put('students', students);
      await _updateLastUpdate('students');
      print('Students saved successfully');
    } catch (e) {
      print('Error saving students: $e');
      rethrow; // Для отладки, чтобы увидеть ошибку выше
    }
  }

  static List<Student>? getStudents() {
    if (_box == null || !_box!.isOpen) return null;
    if (_isCacheValid('students')) {
      return _box!.get('students')?.cast<Student>();
    }
    return null;
  }

  // Attendance (List<Attendance>)
  static Future<void> saveAttendance(List<Attendance> attendance) async {
    await _ensureBoxInitialized();
    print('Saving attendance: ${attendance.length} items');
    await _box!.put('attendance', attendance);
    await _updateLastUpdate('attendance');
    print('Attendance saved');
  }

  static List<Attendance>? getAttendance() {
    if (_box == null || !_box!.isOpen) return null;
    if (_isCacheValid('attendance')) {
      return _box!.get('attendance')?.cast<Attendance>();
    }
    return null;
  }

  // Общие методы
  static Future<void> clearAll() async {
    await _ensureBoxInitialized();
    await _box!.clear();
    print('Box cleared');
  }

  static Future<void> _updateLastUpdate(String key) async {
    await _ensureBoxInitialized();
    print('Updating last update for $key');
    await _box!.put('${key}_lastUpdate', DateTime.now().toIso8601String());
    print('Last update saved for $key');
  }

  static bool _isCacheValid(String key) {
    if (_box == null || !_box!.isOpen) return false;
    final lastUpdateStr = _box!.get('${key}_lastUpdate');
    if (lastUpdateStr == null) return false;
    final lastUpdate = DateTime.parse(lastUpdateStr);
    return DateTime.now().difference(lastUpdate).inHours < cacheExpirationHours;
  }
}