import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<Attendance> _attendanceList = [];
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Attendance> get attendanceList => _attendanceList;
  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🚀 ИСПРАВЛЕНИЕ: Добавлен метод fetchStudents
  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedStudents = HiveService.getStudents();
      if (cachedStudents != null) {
        _students = cachedStudents;
        // Продолжаем, чтобы проверить, нужно ли обновить кэш в фоне
      }

      final data = await ApiService.getStudents();
      final newStudents = data.map((json) => Student.fromJson(json)).toList();

      if (cachedStudents == null || newStudents.length != _students.length || newStudents.any((s) => !_students.any((existing) => existing.id == s.id))) {
        _students = newStudents;
        await HiveService.saveStudents(_students); 
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Если запрос падает, и у нас есть кэшированные данные, мы их сохраняем
      if (_students.isEmpty) {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🚀 ОБНОВЛЕННЫЙ МЕТОД: fetchAttendance с логированием и улучшенным кэшированием
  Future<void> fetchAttendance({
    String? groupId,
    String? date,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cacheKey = groupId != null && date != null 
        ? 'attendance_${groupId}_$date' 
        : 'attendance_all';

    if (!forceRefresh) {
      final cachedData = HiveService.getGeneric<List<Attendance>>(cacheKey);
      if (cachedData != null) {
        print('Using cached attendance for key: $cacheKey, count: ${cachedData.length}');
        if (groupId != null || date != null) {
          // Merge with existing list
          _attendanceList.removeWhere((a) => 
            (groupId == null || a.groupId == groupId) &&
            (date == null || a.date.toIso8601String().split('T')[0] == date)
          );
          _attendanceList.addAll(cachedData);
        } else {
          _attendanceList = cachedData;
        }
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      print('Fetching attendance from API: groupId=$groupId, date=$date');
      final data = await ApiService.getAttendance(groupId: groupId, date: date);
      print('API returned ${data.length} attendance records');
      
      final newAttendances = data.map((json) => Attendance.fromJson(json)).toList();

      if (groupId != null || date != null) {
        _attendanceList.removeWhere((a) {
          bool matchGroup = groupId == null || a.groupId == groupId;
          bool matchDate = date == null || a.date.toIso8601String().split('T')[0] == date;
          return matchGroup && matchDate;
        });
        _attendanceList.addAll(newAttendances);
      } else {
        _attendanceList = newAttendances;
      }

      print('Saving to Hive with key: $cacheKey, count: ${newAttendances.length}');
      // Важно: сохраняем newAttendances, а не _attendanceList, для точного кэша
      await HiveService.saveGeneric(cacheKey, newAttendances, const Duration(hours: 1)); 
      await HiveService.saveAttendance(_attendanceList); // Update main cache
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Fetch attendance error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createAttendance(Map<String, dynamic> data) async {
    try {
      final resp = await ApiService.createAttendance(data);
      final newId = resp['_id'] ?? resp['id'];
      return newId;
    } catch (e) {
      _error = e.toString();
      print('Create attendance error: $_error');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateAttendance(id, data);
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        _error = 'Конфликт: запись была обновлена другим пользователем. Пожалуйста, обновите страницу.';
      } else {
        _error = e.toString();
      }
      print('Update attendance error: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttendance(String id) async {
    try {
      await ApiService.deleteAttendance(id);
      _attendanceList.removeWhere((a) => a.id == id);
      await HiveService.saveAttendance(_attendanceList);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Delete attendance error: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, Map<String, String>>> getAttendances(String groupId, String date) async {
    // Вызов fetchAttendance здесь корректен, так как он использует кэш или принудительно обновляется в AttendanceScreen
    await fetchAttendance(groupId: groupId, date: date); 
    Map<String, Map<String, String>> attendances = {};
    for (var att in _attendanceList) {
      String attDate = att.date.toIso8601String().split('T')[0];
      if (attDate == date && att.groupId == groupId && att.status.isNotEmpty) {
        attendances[att.studentId] = {'status': att.status, 'id': att.id};
      }
    }
    return attendances;
  }

  Attendance getStudentAttendance(String studentId, String date) {
    return _attendanceList.firstWhere(
      (a) => a.studentId == studentId && a.date.toIso8601String().split('T')[0] == date,
      orElse: () => Attendance(
        id: '',
        studentId: studentId,
        groupId: '',
        date: DateTime.parse(date),
        status: 'unmarked',
        updatedBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void handleAttendanceUpdate(DateTime date, String newStatus, {String? id, required Map<String, dynamic> data}) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      _error = 'Нельзя редактировать отметки в выходные.';
      notifyListeners();
      return; 
    }
    if (id != null) {
      updateAttendance(id, data);
    } else {
      createAttendance(data);
    }
  }
}

extension AttendanceSummary on AttendanceProvider {
  int getGroupStudentCount(String groupId) {
    return students.where((s) => s.groupId == groupId).length;
  }

  Map<String, int> getGroupAttendanceStats(String groupId, String date) {
    final stats = {
      'present': 0,
      'absent': 0,
      'sick': 0,
      'ithub': 0,
      'marked': 0, 
    };

    final groupStudents = students.where((s) => s.groupId == groupId).toList();
    for (final student in groupStudents) {
      final records = attendanceList
          .where((a) => a.studentId == student.id && a.date.toIso8601String().split('T')[0] == date)
          .toList();
      if (records.isNotEmpty) {
        final last = records.last;
        final status = last.status.isEmpty ? 'unmarked' : last.status;
        if (status != 'unmarked') {
          stats[status] = (stats[status] ?? 0) + 1;
          // ✅ ИСПРАВЛЕНО: Любой статус, кроме 'unmarked', считается отмеченным
          stats['marked'] = (stats['marked'] ?? 0) + 1;
        }
      }
    }
    return stats;
  }
}