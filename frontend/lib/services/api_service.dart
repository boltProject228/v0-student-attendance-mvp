// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import 'hive_service.dart';

class ApiService {
  // База URL: localhost для Web/iOS
  static String get baseUrl {
    // Для Web и тестирования
    return 'http://localhost:5000/api';
    // Для продакшена: 'https://your-domain.com/api'
    // Для реального устройства: 'http://<YOUR_MACHINE_IP>:5000/api' (например, 'http://192.168.1.100:5000/api')
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
    final response = await _post('/auth/login', {'login': login, 'password': password});
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userJson);
      await HiveService.saveToken(token);
      await HiveService.saveUser(user);
      return data;
    }
    throw Exception('Login failed: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> logout() async {
    try {
      await HiveService.removeToken();
      await HiveService.removeUser();
    } catch (_) {
      // ignore errors on logout
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/auth/me');
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to get current user: ${response.statusCode} ${response.data['error']}');
  }

  // -------------------
  // Groups / Students / Attendance
  // -------------------
  static Future<List<dynamic>> getGroups() async {
    final response = await _get('/groups');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load groups: ${response.statusCode} ${response.data['error']}');
  }

  static Future<List<dynamic>> getStudents() async {
    final response = await _get('/students');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode} ${response.data['error']}');
  }

  static Future<List<dynamic>> getAttendance({String? groupId, String? date}) async {
    final query = <String, dynamic>{};
    if (groupId != null) query['groupId'] = groupId;
    if (date != null) query['date'] = date;
    final response = await _get('/attendance', queryParameters: query.isNotEmpty ? query : null);
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load attendance: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    final response = await _post('/attendance', data);
    if (response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to create attendance: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> data) async {
    final response = await _put('/attendance/$id', data);
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to update attendance: ${response.statusCode} ${response.data['error']}');
  }

  // -------------------
  // Analytics
  // -------------------
  static Future<Map<String, dynamic>> getAnalytics({DateTime? startDate, DateTime? endDate}) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
    if (endDate != null) query['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
    final response = await _get('/analytics', queryParameters: query.isNotEmpty ? query : null);
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to load analytics: ${response.statusCode} ${response.data['error']}');
  }

  static Future<List<dynamic>> getStudentAnalytics(String studentId) async {
    final response = await _get('/analytics/students', queryParameters: {'studentId': studentId});
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load student analytics: ${response.statusCode} ${response.data['error']}');
  }

  // -------------------
  // Admin endpoints (users/groups/students)
  // Note: Removed subjects as they are not in backend
  // -------------------
  static Future<List<dynamic>> getAdminUsers() async {
    final response = await _get('/admin/users');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load users: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _post('/admin/users', data);
    if (response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create user: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> deleteUser(String id) async {
    final response = await _delete('/admin/users/$id');
    if (response.statusCode != 200) throw Exception('Failed to delete user: ${response.statusCode} ${response.data['error']}');
  }

  static Future<List<dynamic>> getAdminGroups() async {
    final response = await _get('/groups');  // Use same as getGroups, or /admin/groups if separate
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load admin groups: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _post('/admin/groups', data);
    if (response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create group: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> deleteGroup(String id) async {
    final response = await _delete('/admin/groups/$id');
    if (response.statusCode != 200) throw Exception('Failed to delete group: ${response.statusCode} ${response.data['error']}');
  }

  static Future<List<dynamic>> getAdminStudents() async {
    final response = await _get('/students');
    if (response.statusCode == 200) return response.data as List<dynamic>;
    throw Exception('Failed to load students: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final response = await _post('/admin/students', data);
    if (response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create student: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> deleteStudent(String id) async {
    final response = await _delete('/admin/students/$id');
    if (response.statusCode != 200) throw Exception('Failed to delete student: ${response.statusCode} ${response.data['error']}');
  }

  // -------------------
  // Setup Admin (if needed, for initial admin creation)
  // -------------------
  static Future<void> setupAdmin(Map<String, dynamic> data) async {
    final response = await _post('/setup/admin', data);
    if (response.statusCode != 201) throw Exception('Failed to setup admin: ${response.statusCode} ${response.data['error']}');
  }

  // -------------------
  // Ping for testing connection
  // -------------------
  static Future<bool> ping() async {
    try {
      final response = await _get('/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}