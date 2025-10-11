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

  static const bool useMock = true; // NEW

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
}