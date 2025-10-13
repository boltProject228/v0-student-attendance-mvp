import 'package:flutter/material.dart';
import '../data/mock_data.dart'; // NEW
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

  static const bool useMock = true; // Установите на false, когда API будет готово

  Future<void> fetchAttendance({String? groupId, String? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cachedAttendance = HiveService.getAttendance();
    if (cachedAttendance != null) {
      _attendanceList = cachedAttendance;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      List<dynamic> data;
      if (useMock) {
        data = MockData.mockGetAttendance().map((a) => a.toJson()).toList();
      } else {
        data = await ApiService.getAttendance(groupId: groupId, date: date);
      }
      _attendanceList = data.map((json) => Attendance.fromJson(json)).toList();
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
      notifyListeners();
      return;
    }

    try {
      List<dynamic> data;
      if (useMock) {
        data = MockData.mockGetStudents().map((s) => s.toJson()).toList();
      } else {
        data = await ApiService.getStudents();
      }
      _students = data.map((json) => Student.fromJson(json)).toList();
      await HiveService.saveStudents(_students);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createAttendance(Map<String, dynamic> data) async {
    try {
      if (!useMock) {
        await ApiService.createAttendance(data);
      } // For mock, simulate
      await fetchAttendance();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      if (!useMock) {
        await ApiService.updateAttendance(id, data);
      } // Simulate
      await fetchAttendance();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, String>> getAttendances(String groupId, String date) async {
    await fetchAttendance(groupId: groupId, date: date);
    Map<String, String> attendances = {};
    for (var att in _attendanceList) {
      // Предполагаем, что date в формате YYYY-MM-DD, и att.date в ISO
      String attDate = att.date.toIso8601String().split('T')[0];
      if (attDate == date && att.groupId == groupId) {  // Если модель Attendance имеет groupId
        attendances[att.studentId] = att.status?.isEmpty ?? true ? 'unmarked' : att.status!;
      }
    }
    // Если для некоторых студентов нет записи, они останутся unmarked в _summary
    return attendances;
  }
}

extension AttendanceSummary on AttendanceProvider {
  /// Возвращает количество студентов по группе
  int getGroupStudentCount(String groupId) {
    return students.where((s) => s.groupId == groupId).length;
  }

  /// Возвращает статистику по посещаемости для группы
  Map<String, int> getGroupAttendanceStats(String groupId) {
    final stats = {
      'present': 0,
      'absent': 0,
      'sick': 0,
      'wsk': 0,
      'marked': 0,
    };

    final groupStudents = students.where((s) => s.groupId == groupId).toList();
    for (final student in groupStudents) {
      final records = attendanceList
          .where((a) => a.studentId == student.id)
          .toList();
      if (records.isNotEmpty) {
        final last = records.last; // берем последний статус
        final status = last.status?.isEmpty ?? true ? 'unmarked' : last.status!;
        if (stats.containsKey(status) && status != 'unmarked') {
          stats[status] = (stats[status]! + 1);
        }
        if (status != 'unmarked') {
          stats['marked'] = stats['marked']! + 1;
        }
      }
    }
    return stats;
  }
}