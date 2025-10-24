import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class HiveService {
  static Box? _box;
  static const String boxName = 'appBox';
  static const int cacheExpirationHours = 24;

  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(AttendanceAdapter().typeId)) Hive.registerAdapter(AttendanceAdapter());
    if (!Hive.isAdapterRegistered(GroupAdapter().typeId)) Hive.registerAdapter(GroupAdapter());
    if (!Hive.isAdapterRegistered(StudentAdapter().typeId)) Hive.registerAdapter(StudentAdapter());
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) Hive.registerAdapter(UserAdapter());
    _box = await Hive.openBox(boxName);
    print('HiveService: box opened: $boxName');
  }

  static Future<void> _ensureBoxInitialized() async {
    if (_box == null || !_box!.isOpen) await init();
  }

  static Future<void> saveToken(String token) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put('token', token);
    } catch (e) {
      print('HiveService.saveToken error: $e');
    }
  }

  static String? getToken() {
    if (_box == null || !_box!.isOpen) return null;
    final token = _box!.get('token');
    return token?.toString();
  }

  static Future<void> removeToken() async {
    await _ensureBoxInitialized();
    await _box!.delete('token');
  }

  static Future<void> saveUser(User user) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put('user', user);
      await _box!.put('user_map', user.toJson());
      await _updateLastUpdate('user');
    } catch (e) {
      print('HiveService.saveUser error: $e');
    }
  }

  static User? getUser() {
    if (_box == null || !_box!.isOpen) return null;
    if (!_isCacheValid('user')) {
      _box!.delete('user');
      _box!.delete('user_map');
      return null;
    }
    final raw = _box!.get('user');
    if (raw == null) {
      final fallback = _box!.get('user_map');
      if (fallback == null) return null;
      return _userFromDynamic(fallback);
    }
    return _userFromDynamic(raw);
  }

  static User? _userFromDynamic(dynamic raw) {
    try {
      if (raw == null) return null;
      if (raw is User) return raw;
      if (raw is Map) return User.fromJson(Map<String, dynamic>.from(raw));
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return User.fromJson(Map<String, dynamic>.from(decoded));
      }
      print('HiveService.getUser(): unexpected type ${raw.runtimeType}');
      return null;
    } catch (e) {
      print('HiveService.getUser(): failed to decode saved user: $e');
      return null;
    }
  }

  static Future<void> removeUser() async {
    await _ensureBoxInitialized();
    await _box!.delete('user');
    await _box!.delete('user_map');
    await _box!.delete('user_lastUpdate');
  }

  static Future<void> saveGroups(List<Group> groups) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put('groups', groups);
      await _box!.put('groups_map', groups.map((g) => g.toJson()).toList());
      await _updateLastUpdate('groups');
    } catch (e) {
      print('HiveService.saveGroups error: $e');
    }
  }

  static List<Group>? getGroups() {
    if (_box == null || !_box!.isOpen) return null;
    if (!_isCacheValid('groups')) {
      _box!.delete('groups');
      _box!.delete('groups_map');
      return null;
    }
    final raw = _box!.get('groups');
    if (raw == null) {
      final rawMap = _box!.get('groups_map');
      if (rawMap == null) return null;
      return _castListFromMap<Group>(rawMap, (m) => Group.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Group>(raw, (m) => Group.fromJson(Map<String, dynamic>.from(m)));
  }

  static Future<void> saveStudents(List<Student> students) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put('students', students);
      await _box!.put('students_map', students.map((s) => s.toJson()).toList());
      await _updateLastUpdate('students');
    } catch (e) {
      print('HiveService.saveStudents error: $e');
    }
  }

  static List<Student>? getStudents() {
    if (_box == null || !_box!.isOpen) return null;
    if (!_isCacheValid('students')) {
      _box!.delete('students');
      _box!.delete('students_map');
      return null;
    }
    final raw = _box!.get('students');
    if (raw == null) {
      final rawMap = _box!.get('students_map');
      if (rawMap == null) return null;
      return _castListFromMap<Student>(rawMap, (m) => Student.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Student>(raw, (m) => Student.fromJson(Map<String, dynamic>.from(m)));
  }

  static Future<void> saveAttendance(List<Attendance> attendance) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put('attendance', attendance);
      await _box!.put('attendance_map', attendance.map((a) => a.toJson()).toList());
      await _updateLastUpdate('attendance');
    } catch (e) {
      print('HiveService.saveAttendance error: $e');
    }
  }

  static List<Attendance>? getAttendance() {
    if (_box == null || !_box!.isOpen) return null;
    if (!_isCacheValid('attendance')) {
      _box!.delete('attendance');
      _box!.delete('attendance_map');
      return null;
    }
    final raw = _box!.get('attendance');
    if (raw == null) {
      final rawMap = _box!.get('attendance_map');
      if (rawMap == null) return null;
      return _castListFromMap<Attendance>(rawMap, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Attendance>(raw, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)));
  }

  // Новый метод для получения посещаемости по группе
  static Future<List<Attendance>?> getAttendanceForGroup(String groupId) async {
    await _ensureBoxInitialized();
    if (_box == null || !_box!.isOpen) return null;
    if (!_isCacheValid('attendance')) {
      _box!.delete('attendance');
      _box!.delete('attendance_map');
      return null;
    }
    final raw = _box!.get('attendance');
    if (raw == null) {
      final rawMap = _box!.get('attendance_map');
      if (rawMap == null) return null;
      return _castListFromMap<Attendance>(rawMap, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)))
          ?.where((a) => a.groupId == groupId)
          .toList();
    }
    return _castListFromDynamic<Attendance>(raw, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)))
        ?.where((a) => a.groupId == groupId)
        .toList();
  }

  static Future<void> clearAll() async {
    await _ensureBoxInitialized();
    await _box!.clear();
  }

  static Future<void> _updateLastUpdate(String key) async {
    await _ensureBoxInitialized();
    await _box!.put('${key}_lastUpdate', DateTime.now().toIso8601String());
  }

  static bool _isCacheValid(String key) {
    if (_box == null || !_box!.isOpen) return false;
    final lastUpdateStr = _box!.get('${key}_lastUpdate') as String?;
    if (lastUpdateStr == null) return false;
    final lastUpdate = DateTime.tryParse(lastUpdateStr);
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate).inHours < cacheExpirationHours;
  }

  static List<T>? _castListFromDynamic<T>(dynamic raw, T Function(Map<String, dynamic>) fromMap) {
    try {
      if (raw is List<T>) return raw.cast<T>();
      if (raw is List) {
        if (raw.isEmpty) return <T>[];
        final first = raw.first;
        if (first is T) return raw.cast<T>();
        if (first is Map) return raw.map<T>((e) => fromMap(Map<String, dynamic>.from(e))).toList();
        print('HiveService: unexpected list element type ${first.runtimeType}');
        return null;
      }
      return null;
    } catch (e) {
      print('HiveService._castListFromDynamic error: $e');
      return null;
    }
  }

  static List<T>? _castListFromMap<T>(dynamic rawMap, T Function(Map<String, dynamic>) fromMap) {
    try {
      if (rawMap is List) return rawMap.map<T>((e) => fromMap(Map<String, dynamic>.from(e))).toList();
      return null;
    } catch (e) {
      print('HiveService._castListFromMap error: $e');
      return null;
    }
  }

  static Future<void> saveGeneric(String key, dynamic value, Duration expiration) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put(key, value);
      await _box!.put('${key}_lastUpdate', DateTime.now().add(expiration).toIso8601String());
    } catch (e) {
      print('HiveService.saveGeneric error: $e');
    }
  }

  static T? getGeneric<T>(String key) {
    if (_box == null || !_box!.isOpen) return null;
    final expirationStr = _box!.get('${key}_lastUpdate') as String?;
    if (expirationStr == null) {
      _box!.delete(key);
      return null;
    }
    final expiration = DateTime.tryParse(expirationStr);
    if (expiration == null || DateTime.now().isAfter(expiration)) {
      _box!.delete(key);
      _box!.delete('${key}_lastUpdate');
      return null;
    }
    final value = _box!.get(key);
    return value is T ? value : null;
  }
}