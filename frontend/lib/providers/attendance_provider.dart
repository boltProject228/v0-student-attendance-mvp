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
  String? _selectedGroupId; // Для отслеживания выбранной группы

  List<Attendance> get attendanceList => _attendanceList;
  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedGroupId => _selectedGroupId;

  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedStudents = HiveService.getStudents();
      if (cachedStudents != null) {
        _students = cachedStudents;
      } else {
        final data = await ApiService.getStudents();
        _students = (data as List<dynamic>).map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
        await HiveService.saveStudents(_students);
      }

      _isLoading = false;
      notifyListeners();
      print('Fetched students: ${_students.length}');
    } catch (e) {
      _error = 'Failed to load students: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendance({
    String? groupId,
    String? date,
    bool forceRefresh = false,
  }) async {
    if (groupId == null) {
      _error = 'No group selected for attendance fetch';
      print('AttendanceProvider: No groupId provided');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _selectedGroupId = groupId;
    notifyListeners();

    try {
      print('Fetching attendance from API: groupId=$groupId, date=$date at ${DateTime.now()}');
      List<Attendance>? cachedData;
      if (!forceRefresh) {
        cachedData = await HiveService.getAttendanceForGroup(groupId);
      }
      final data = cachedData ?? await ApiService.getAttendance(groupId: groupId, date: date);

      if (data is List) {
        final newAttendances = <Attendance>[];
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            try {
              final attendance = Attendance.fromJson(item);
              if (attendance.groupId == groupId && (date == null || attendance.date.toIso8601String().split('T')[0] == date)) {
                newAttendances.add(attendance);
              }
            } catch (e) {
              print('Error parsing attendance item: $e, skipping item: $item');
            }
          } else {
            print('Unexpected attendance data type: ${item.runtimeType}, using fallback');
            newAttendances.add(Attendance(
              id: 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
              studentId: '',
              groupId: groupId,
              date: DateTime.now(),
              status: 'unmarked',
              updatedBy: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              updatedByName: null,
              updatedByRole: null,
            ));
          }
        }

        // Удаляем старые записи только для указанной даты и группы
        if (date != null) {
          _attendanceList.removeWhere((a) => a.groupId == groupId && a.date.toIso8601String().split('T')[0] == date);
        }
        _attendanceList.addAll(newAttendances.where((a) => !_attendanceList.any((existing) => existing.id == a.id)));

        await HiveService.saveAttendance(_attendanceList);
        print('API returned ${newAttendances.length} attendance records for group $groupId at ${DateTime.now()}');
      } else {
        print('Unexpected API response format for attendance: ${data.runtimeType}');
        _error = 'Invalid API response format: Expected List, got ${data.runtimeType}';
      }
    } catch (e) {
      print('Fetch attendance error: $e at ${DateTime.now()}');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createAttendance(Map<String, dynamic> data) async {
    try {
      final resp = await ApiService.createAttendance(data);
      final newId = resp['_id'] ?? resp['id'];
      if (newId != null) {
        await fetchAttendance(groupId: data['groupId'], date: data['date'], forceRefresh: true);
      }
      return newId;
    } catch (e) {
      _error = e.toString();
      print('Create attendance error: $_error at ${DateTime.now()}');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateAttendance(id, data);
      await fetchAttendance(groupId: data['groupId'], date: data['date'], forceRefresh: true);
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        _error = 'Конфликт: запись была обновлена другим пользователем. Пожалуйста, обновите страницу.';
      } else {
        _error = e.toString();
      }
      print('Update attendance error: $_error at ${DateTime.now()}');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttendance(String id) async {
    try {
      final attendance = _attendanceList.firstWhere((a) => a.id == id);
      await ApiService.deleteAttendance(id);
      _attendanceList.removeWhere((a) => a.id == id);
      await HiveService.saveAttendance(_attendanceList);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Delete attendance error: $_error at ${DateTime.now()}');
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, String>>> getAttendances(String groupId, String date) async {
    await fetchAttendance(groupId: groupId, date: date, forceRefresh: false); // Используем кэш, если доступен
    final attendances = _attendanceList
        .where((a) => a.groupId == groupId && a.date.toIso8601String().split('T')[0] == date && a.status.isNotEmpty)
        .map((a) => {'status': a.status, 'id': a.id})
        .toList();
    return attendances;
  }

  Attendance getStudentAttendance(String studentId, String date) {
    return _attendanceList.firstWhere(
      (a) => a.studentId == studentId && a.date.toIso8601String().split('T')[0] == date,
      orElse: () => Attendance(
        id: '',
        studentId: studentId,
        groupId: _selectedGroupId ?? '',
        date: DateTime.parse(date),
        status: 'unmarked',
        updatedBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        updatedByName: null,
        updatedByRole: null,
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

  void setSelectedGroupId(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
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

    if (students.isEmpty) {
      print('Warning: No students loaded for group $groupId');
      return stats;
    }

    final groupStudents = students.where((s) => s.groupId == groupId).toList();
    for (final student in groupStudents) {
      final records = _attendanceList
          .where((a) => a.studentId == student.id && a.date.toIso8601String().split('T')[0] == date)
          .toList();
      if (records.isNotEmpty) {
        final last = records.last;
        final status = last.status.isEmpty ? 'unmarked' : last.status;
        if (status != 'unmarked') {
          stats[status] = (stats[status] ?? 0) + 1;
          stats['marked'] = (stats['marked'] ?? 0) + 1;
        }
      } else {
        stats['unmarked'] = (stats['unmarked'] ?? 0) + 1;
      }
    }
    print('Stats for group $groupId on $date: $stats');
    return stats;
  }
}