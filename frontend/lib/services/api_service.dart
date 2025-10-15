// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import 'hive_service.dart';

class ApiService {
  // Если используешь Android эмулятор -> 10.0.2.2, если реальный девайс или web -> localhost
  static String get baseUrl {
    // return 'http://10.0.2.2:5000/api'; // android emulator
    return 'http://localhost:5000/api';
  }

  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _getHeaders() async {
    final token = HiveService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _get(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.get(uri, headers: headers).timeout(_timeout);
  }

  static Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
  }

  static Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
  }

  static Future<http.Response> _delete(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.delete(uri, headers: headers).timeout(_timeout);
  }

  // -------------------
  // Auth
  // -------------------
  static Future<Map<String, dynamic>> login(String login, String password) async {
    if (MockData.mockGetUsers().isNotEmpty) {
      return MockData.mockLogin(login, password);
    }
    final response = await _post('/auth/login', {'login': login, 'password': password});
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Login failed: ${response.statusCode} ${response.body}');
  }

  static Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } catch (_) {
      // ignore errors on logout
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/auth/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get current user: ${response.statusCode}');
  }

  // -------------------
  // Groups / Students / Attendance
  // -------------------
  static Future<List<dynamic>> getGroups() async {
    if (MockData.mockGetGroups().isNotEmpty) {
      return MockData.mockGetGroups().map((g) => g.toJson()).toList();
    }
    final response = await _get('/groups');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load groups: ${response.statusCode}');
  }

  static Future<List<dynamic>> getStudents() async {
    if (MockData.mockGetStudents().isNotEmpty) {
      return MockData.mockGetStudents().map((s) => s.toJson()).toList();
    }
    final response = await _get('/students');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAttendance({String? groupId, String? date}) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return MockData.mockGetAttendance().map((a) => a.toJson()).toList();
    }
    String endpoint = '/attendance?';
    if (groupId != null) endpoint += 'groupId=$groupId&';
    if (date != null) endpoint += 'date=$date';
    final response = await _get(endpoint);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load attendance: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return data;
    }
    final response = await _post('/attendance', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create attendance: ${response.statusCode}');
  }

  // Update accepts ?id=... like in your client code (можно поменять на /attendance/:id на бэке)
  static Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> data) async {
    final response = await _put('/attendance?id=$id', data);
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to update attendance: ${response.statusCode}');
  }

  // -------------------
  // Analytics
  // -------------------
  static Future<Map<String, dynamic>> getAnalytics({DateTime? startDate, DateTime? endDate}) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return MockData.mockGetAnalytics(startDate: startDate, endDate: endDate);
    }
    String endpoint = '/analytics?';
    if (startDate != null) endpoint += 'startDate=${DateFormat('yyyy-MM-dd').format(startDate)}&';
    if (endDate != null) endpoint += 'endDate=${DateFormat('yyyy-MM-dd').format(endDate)}';
    final response = await _get(endpoint);
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load analytics: ${response.statusCode}');
  }

  static Future<List<dynamic>> getStudentAnalytics(String studentId) async {
    final response = await _get('/analytics/students?studentId=$studentId');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load student analytics: ${response.statusCode}');
  }

  // -------------------
  // Admin endpoints (users/groups/students/subjects)
  // -------------------
  static Future<List<dynamic>> getAdminUsers() async {
    if (MockData.mockGetUsers().isNotEmpty) return MockData.mockGetUsers().map((u) => u.toJson()).toList();
    final response = await _get('/admin/users');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load users: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _post('/admin/users', data);
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to create user: ${response.statusCode}');
  }

  static Future<void> deleteUser(String id) async {
    final response = await _delete('/admin/users?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete user: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAdminGroups() async {
    if (MockData.mockGetGroups().isNotEmpty) return MockData.mockGetGroups().map((g) => g.toJson()).toList();
    final response = await _get('/admin/groups');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load admin groups: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _post('/admin/groups', data);
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to create group: ${response.statusCode}');
  }

  static Future<void> deleteGroup(String id) async {
    final response = await _delete('/admin/groups?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete group: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAdminStudents() async {
    if (MockData.mockGetStudents().isNotEmpty) return MockData.mockGetStudents().map((s) => s.toJson()).toList();
    final response = await _get('/admin/students');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final response = await _post('/admin/students', data);
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to create student: ${response.statusCode}');
  }

  static Future<void> deleteStudent(String id) async {
    final response = await _delete('/admin/students?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete student: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAdminSubjects() async {
    final response = await _get('/admin/subjects');
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to load subjects: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final response = await _post('/admin/subjects', data);
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to create subject: ${response.statusCode}');
  }

  static Future<void> deleteSubject(String id) async {
    final response = await _delete('/admin/subjects?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete subject: ${response.statusCode}');
  }
}
