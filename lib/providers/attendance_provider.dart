import 'package:flutter/material.dart';
import '../data/mock_data.dart';
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

  static const bool useMock = true;

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

  Future<String?> createAttendance(Map<String, dynamic> data) async {
    try {
      String? newId;
      if (!useMock) {
        final resp = await ApiService.createAttendance(data);
        newId = resp['_id'] ?? resp['id'];
        await fetchAttendance();
      } else {
        newId = 'a${_attendanceList.length + 1}';
        var newAtt = Attendance(
          id: newId,
          studentId: data['studentId'],
          groupId: data['groupId'],
          date: DateTime.parse(data['date']),
          status: data['status'],
          updatedBy: data['updatedBy'] ?? '1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _attendanceList.add(newAtt);
        await HiveService.saveAttendance(_attendanceList);
      }
      notifyListeners();
      return newId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      if (!useMock) {
        await ApiService.updateAttendance(id, data);
        await fetchAttendance();
      } else {
        bool found = false;
        for (int i = 0; i < _attendanceList.length; i++) {
          if (_attendanceList[i].id == id) {
            _attendanceList[i] = _attendanceList[i].copyWith(
              status: data['status'],
              updatedBy: data['updatedBy'] ?? _attendanceList[i].updatedBy,
              updatedAt: DateTime.now(),
            );
            found = true;
            break;
          }
        }
        if (!found) {
          throw 'Attendance not found';
        }
        await HiveService.saveAttendance(_attendanceList);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, Map<String, String>>> getAttendances(String groupId, String date) async {
    await fetchAttendance(groupId: groupId, date: date);
    Map<String, Map<String, String>> attendances = {};
    for (var att in _attendanceList) {
      String attDate = att.date.toIso8601String().split('T')[0];
      if (attDate == date && att.groupId == groupId) {
        String status = att.status.isEmpty ? 'unmarked' : att.status;
        attendances[att.studentId] = {'status': status, 'id': att.id};
      }
    }
    return attendances;
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
      'wsk': 0,
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