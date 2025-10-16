// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import 'hive_service.dart';

class ApiService {
  // База URL: localhost для Web/iOS
  static String get baseUrl {
    // Для Web
    return 'http://localhost:5000/api';
    // Для реального устройства замени на: 'http://<PUBLIC_IP>:5000/api' (например, 'http://46.42.238.111:5000/api')
  }

  static final Dio _dio = Dio()
    ..options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );

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

  static Future<Response> _get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    final headers = await _getHeaders();
    return await _dio.get(
      endpoint,
      options: Options(headers: headers),
      queryParameters: queryParameters,
    );
  }

  static Future<Response> _post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await _dio.post(
      endpoint,
      data: body,
      options: Options(headers: headers),
    );
  }

  static Future<Response> _put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await _dio.put(
      endpoint,
      data: body,
      options: Options(headers: headers),
    );
  }

  static Future<Response> _delete(String endpoint) async {
    final headers = await _getHeaders();
    return await _dio.delete(
      endpoint,
      options: Options(headers: headers),
    );
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
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Login failed: ${response.statusCode} ${response.data}');
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
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to get current user: ${response.statusCode} ${response.data}');
  }

  // -------------------
  // Groups / Students / Attendance
  // -------------------
  static Future<List<dynamic>> getGroups() async {
    if (MockData.mockGetGroups().isNotEmpty) {
      return MockData.mockGetGroups().map((g) => g.toJson()).toList();
    }
    final response = await _get('/groups');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load groups: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getStudents() async {
    if (MockData.mockGetStudents().isNotEmpty) {
      return MockData.mockGetStudents().map((s) => s.toJson()).toList();
    }
    final response = await _get('/students');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getAttendance({String? groupId, String? date}) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return MockData.mockGetAttendance().map((a) => a.toJson()).toList();
    }
    final query = <String, dynamic>{};
    if (groupId != null) query['groupId'] = groupId;
    if (date != null) query['date'] = date;
    final response = await _get('/attendance', queryParameters: query.isNotEmpty ? query : null);
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load attendance: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return data;
    }
    final response = await _post('/attendance', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to create attendance: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> data) async {
    final response = await _put('/attendance?id=$id', data);
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to update attendance: ${response.statusCode} ${response.data}');
  }

  // -------------------
  // Analytics
  // -------------------
  static Future<Map<String, dynamic>> getAnalytics({DateTime? startDate, DateTime? endDate}) async {
    if (MockData.mockGetAttendance().isNotEmpty) {
      return MockData.mockGetAnalytics(startDate: startDate, endDate: endDate);
    }
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
    if (endDate != null) query['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
    final response = await _get('/analytics', queryParameters: query.isNotEmpty ? query : null);
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to load analytics: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getStudentAnalytics(String studentId) async {
    final response = await _get('/analytics/students', queryParameters: {'studentId': studentId});
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load student analytics: ${response.statusCode} ${response.data}');
  }

  // -------------------
  // Admin endpoints (users/groups/students/subjects)
  // -------------------
  static Future<List<dynamic>> getAdminUsers() async {
    if (MockData.mockGetUsers().isNotEmpty) return MockData.mockGetUsers().map((u) => u.toJson()).toList();
    final response = await _get('/admin/users');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load users: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _post('/admin/users', data);
    if (response.statusCode == 200 || response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create user: ${response.statusCode} ${response.data}');
  }

  static Future<void> deleteUser(String id) async {
    final response = await _delete('/admin/users?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete user: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getAdminGroups() async {
    if (MockData.mockGetGroups().isNotEmpty) return MockData.mockGetGroups().map((g) => g.toJson()).toList();
    final response = await _get('/admin/groups');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load admin groups: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _post('/admin/groups', data);
    if (response.statusCode == 200 || response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create group: ${response.statusCode} ${response.data}');
  }

  static Future<void> deleteGroup(String id) async {
    final response = await _delete('/admin/groups?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete group: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getAdminStudents() async {
    if (MockData.mockGetStudents().isNotEmpty) return MockData.mockGetStudents().map((s) => s.toJson()).toList();
    final response = await _get('/admin/students');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final response = await _post('/admin/students', data);
    if (response.statusCode == 200 || response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create student: ${response.statusCode} ${response.data}');
  }

  static Future<void> deleteStudent(String id) async {
    final response = await _delete('/admin/students?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete student: ${response.statusCode} ${response.data}');
  }

  static Future<List<dynamic>> getAdminSubjects() async {
    final response = await _get('/admin/subjects');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load subjects: ${response.statusCode} ${response.data}');
  }

  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final response = await _post('/admin/subjects', data);
    if (response.statusCode == 200 || response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create subject: ${response.statusCode} ${response.data}');
  }

  static Future<void> deleteSubject(String id) async {
    final response = await _delete('/admin/subjects?id=$id');
    if (response.statusCode != 200) throw Exception('Failed to delete subject: ${response.statusCode} ${response.data}');
  }
}