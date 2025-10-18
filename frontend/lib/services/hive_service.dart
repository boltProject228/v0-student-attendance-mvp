// lib/services/hive_service.dart
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

    // Регистрация адаптеров — безопасно (проверяем по typeId)
    try {
      if (!Hive.isAdapterRegistered(AttendanceAdapter().typeId)) {
        Hive.registerAdapter(AttendanceAdapter());
      }
    } catch (e) {
      // ignore if adapter class missing at runtime - но обычно это не должно случаться
      print('Hive: attendance adapter registration error: $e');
    }
    try {
      if (!Hive.isAdapterRegistered(GroupAdapter().typeId)) {
        Hive.registerAdapter(GroupAdapter());
      }
    } catch (e) {
      print('Hive: group adapter registration error: $e');
    }
    try {
      if (!Hive.isAdapterRegistered(StudentAdapter().typeId)) {
        Hive.registerAdapter(StudentAdapter());
      }
    } catch (e) {
      print('Hive: student adapter registration error: $e');
    }
    try {
      if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
        Hive.registerAdapter(UserAdapter());
      }
    } catch (e) {
      print('Hive: user adapter registration error: $e');
    }

    _box = await Hive.openBox(boxName);
    print('HiveService: box opened: $boxName');
  }

  static Future<void> _ensureBoxInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }

  // ---------------- token ----------------
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
    final t = _box!.get('token');
    if (t == null) return null;
    return t.toString();
  }

  static Future<void> removeToken() async {
    await _ensureBoxInitialized();
    await _box!.delete('token');
  }

  // ---------------- user ----------------
  static Future<void> saveUser(User user) async {
    await _ensureBoxInitialized();
    try {
      // Сохраняем как объект (Hive adapter) и как Map (резерв)
      await _box!.put('user', user);
      await _box!.put('user_map', user.toJson());
    } catch (e) {
      print('HiveService.saveUser error: $e');
    }
  }

  static User? getUser() {
    if (_box == null || !_box!.isOpen) return null;
    final raw = _box!.get('user');
    if (raw == null) {
      // попробуем резервную копию map или json-string
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
      if (raw is Map) {
        // Map может содержать dynamic values — приводим
        final map = Map<String, dynamic>.from(raw);
        return User.fromJson(map);
      }
      if (raw is String) {
        // может быть JSON-строка
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return User.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      // В некоторых случаях библиотека могла сохранить List или другой тип
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
  }

  // ---------------- groups ----------------
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
    if (!_isCacheValid('groups')) return null;
    final raw = _box!.get('groups');
    if (raw == null) {
      final rawMap = _box!.get('groups_map');
      if (rawMap == null) return null;
      return _castListFromMap<Group>(rawMap, (m) => Group.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Group>(raw, (m) => Group.fromJson(Map<String, dynamic>.from(m)));
  }

  // ---------------- students ----------------
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
    if (!_isCacheValid('students')) return null;
    final raw = _box!.get('students');
    if (raw == null) {
      final rawMap = _box!.get('students_map');
      if (rawMap == null) return null;
      return _castListFromMap<Student>(rawMap, (m) => Student.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Student>(raw, (m) => Student.fromJson(Map<String, dynamic>.from(m)));
  }

  // ---------------- attendance ----------------
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
    if (!_isCacheValid('attendance')) return null;
    final raw = _box!.get('attendance');
    if (raw == null) {
      final rawMap = _box!.get('attendance_map');
      if (rawMap == null) return null;
      return _castListFromMap<Attendance>(rawMap, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)));
    }
    return _castListFromDynamic<Attendance>(raw, (m) => Attendance.fromJson(Map<String, dynamic>.from(m)));
  }

  // ---------------- common ----------------
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

  // ---------------- helpers ----------------
  // Попытка привести raw (List) к List<T>. Если элементы уже T -> cast.
  // Иначе, если элементы Map -> мапим через fromMap.
  static List<T>? _castListFromDynamic<T>(dynamic raw, T Function(Map<String, dynamic>) fromMap) {
    try {
      if (raw is List<T>) return raw.cast<T>();
      if (raw is List) {
        if (raw.isEmpty) return <T>[];
        final first = raw.first;
        if (first is T) {
          return raw.cast<T>();
        } else if (first is Map) {
          return raw.map<T>((e) => fromMap(Map<String, dynamic>.from(e))).toList();
        } else {
          print('HiveService: unexpected list element type ${first.runtimeType}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('_castListFromDynamic error: $e');
      return null;
    }
  }

  // Вспомогательная версия, когда rawMap уже явно Map-список
  static List<T>? _castListFromMap<T>(dynamic rawMap, T Function(Map<String, dynamic>) fromMap) {
    try {
      if (rawMap is List) {
        return rawMap.map<T>((e) => fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return null;
    } catch (e) {
      print('_castListFromMap error: $e');
      return null;
    }
  }

  // Generic save
  static Future<void> saveGeneric(String key, dynamic value, Duration expiration) async {
    await _ensureBoxInitialized();
    try {
      await _box!.put(key, value);
      await _box!.put('${key}_lastUpdate', DateTime.now().add(expiration).toIso8601String());
    } catch (e) {
      print('HiveService.saveGeneric error: $e');
    }
  }

  // Generic get
  static T? getGeneric<T>(String key) {
    if (_box == null || !_box!.isOpen) return null;
    final expirationStr = _box!.get('${key}_lastUpdate') as String?;
    if (expirationStr == null) return null;
    final expiration = DateTime.tryParse(expirationStr);
    if (expiration == null || DateTime.now().isAfter(expiration)) {
      _box!.delete(key);
      _box!.delete('${key}_lastUpdate');
      return null;
    }
    return _box!.get(key) as T?;
  }
}