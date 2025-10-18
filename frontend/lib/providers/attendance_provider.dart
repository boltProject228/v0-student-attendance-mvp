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

  Future<void> fetchAttendance({String? groupId, String? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (groupId == null && date == null) {
      final cachedAttendance = HiveService.getAttendance();
      if (cachedAttendance != null) {
        _attendanceList = cachedAttendance;
        _isLoading = false;
        // notifyListeners(); // ⚠️ Не вызываем здесь, чтобы избежать конфликта, если вызвано в build/init
        return;
      }
    }

    try {
      final data = await ApiService.getAttendance(groupId: groupId, date: date);
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

      await HiveService.saveAttendance(_attendanceList);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudents() async {
    final cachedStudents = HiveService.getStudents();
    if (cachedStudents != null) {
      _students = cachedStudents;
      // notifyListeners(); // ❌ ИСПРАВЛЕНО: Удален синхронный notifyListeners при наличии кеша
      return;
    }

    try {
      final data = await ApiService.getStudents();
      _students = data.map((json) => Student.fromJson(json)).toList();
      await HiveService.saveStudents(_students);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> createAttendance(Map<String, dynamic> data) async {
    try {
      final resp = await ApiService.createAttendance(data);
      final newId = resp['_id'] ?? resp['id'];
      await fetchAttendance();
      return newId;
    } catch (e) {
      _error = e.toString();
      print('Create attendance error: $_error'); // Лог для дебага
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateAttendance(id, data);
      await fetchAttendance();
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        _error = 'Конфликт: запись была обновлена другим пользователем. Пожалуйста, обновите страницу.';
      } else {
        _error = e.toString();
      }
      print('Update attendance error: $_error'); // Лог
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
      print('Delete attendance error: $_error'); // Лог
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, Map<String, String>>> getAttendances(String groupId, String date) async {
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
          stats['marked'] = (stats['marked'] ?? 0) + 1;
        }
      }
    }
    return stats;
  }
}