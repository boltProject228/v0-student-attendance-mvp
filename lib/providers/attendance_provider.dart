import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart'; // NEW

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

    // NEW: Проверяем кэш
    final cachedAttendance = HiveService.getAttendance();
    if (cachedAttendance != null) {
      _attendanceList = cachedAttendance;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await ApiService.getAttendance(
        groupId: groupId,
        date: date,
      );
      _attendanceList = data.map((json) => Attendance.fromJson(json)).toList();
      await HiveService.saveAttendance(_attendanceList); // Сохраняем
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudents() async {
    // NEW: Проверяем кэш
    final cachedStudents = HiveService.getStudents();
    if (cachedStudents != null) {
      _students = cachedStudents;
      notifyListeners();
      return;
    }

    try {
      final data = await ApiService.getStudents();
      _students = data.map((json) => Student.fromJson(json)).toList();
      await HiveService.saveStudents(_students); // Сохраняем
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createAttendance(Map<String, dynamic> data) async {
    try {
      await ApiService.createAttendance(data);
      // NEW: После создания — перезагружаем и сохраняем кэш
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
      await ApiService.updateAttendance(id, data);
      // NEW: Перезагружаем кэш
      await fetchAttendance();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}