import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/group.dart';
import 'hive_service.dart';

class ApiService {
  static String get baseUrl => 'http://localhost:5000/api';

  static final Dio _dio = Dio()
    ..options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // Увеличен для обработки больших данных
      sendTimeout: const Duration(seconds: 60),    // Увеличен для отправки больших данных
      maxRedirects: 5,
      // Установка максимального размера тела запроса (опционально, если сервер поддерживает)
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    )
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = HiveService.getToken();
        options.headers['Content-Type'] = 'application/json';
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException err, handler) {
        print('Dio Error: ${err.message}');
        return handler.next(err);
      },
    ));

  // ------------------------------
  // 🔹 Generic HTTP helpers
  // ------------------------------
  static Future<Response> _get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      return await _dio.post(endpoint, data: body);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> _put(String endpoint, Map<String, dynamic> body) async {
    try {
      return await _dio.put(endpoint, data: body);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> _delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------
  // 🔹 Auth
  // ------------------------------
  static Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await _post('/auth/login', {'login': login, 'password': password});
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      await HiveService.saveToken(token);
      await HiveService.saveUser(User.fromJson(userJson));
      return data;
    }
    throw Exception('Login failed: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> logout() async {
    await HiveService.removeToken();
    await HiveService.removeUser();
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/auth/me');
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to get current user: ${response.statusCode} ${response.data['error']}');
  }

  // ------------------------------
  // 🔹 Groups / Students / Attendance
  // ------------------------------
// Groups / Students / Attendance
  static Future<List<Group>> getGroups() async {
  final response = await _get('/groups');
  if (response.statusCode == 200) {
    return (response.data as List<dynamic>).map((json) {
      if (json is Map<String, dynamic>) {
        return Group.fromJson(json);
      } else {
        print('Unexpected group data: $json, using fallback');
        return Group(
          id: 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Unknown Group',
          specialty: 'Unknown Specialty',
          course: 1,
          createdAt: DateTime.now(),
        );
      }
    }).toList();
  }
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
    if (response.statusCode == 201) return response.data as Map<String, dynamic>;
    throw Exception('Failed to create attendance: ${response.statusCode} ${response.data['error']}');
  }

  static Future<Map<String, dynamic>> updateAttendance(String id, Map<String, dynamic> data) async {
    final response = await _put('/attendance/$id', data);
    if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    throw Exception('Failed to update attendance: ${response.statusCode} ${response.data['error']}');
  }

  static Future<void> deleteAttendance(String id) async {
    final response = await _delete('/attendance/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete attendance: ${response.statusCode} ${response.data['error']}');
    }
  }

  // ------------------------------
  // 🔹 Analytics
  // ------------------------------
static Future<Map<String, dynamic>> getGroupAnalytics({
  required String groupId,
  required String startDate,
  required String endDate,
  String period = 'day',
}) async {
  final response = await _get('/analytics/group/$groupId', queryParameters: {
    'startDate': startDate,
    'endDate': endDate,
    'period': period,
  });
  if (response.statusCode == 200) {
    return response.data;
  }
  throw Exception('Failed to load group analytics: ${response.statusCode} ${response.data['error']}');
}

  // ------------------------------
  // 🔹 Admin (simplified endpoints)
  // ------------------------------
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

  static Future<List<Group>> getAdminGroups() async {
    final response = await _get('/admin/groups');
    if (response.statusCode == 200) {
      return (response.data as List<dynamic>).map((json) => Group.fromJson(json)).toList();
    }
    throw Exception('Failed to load groups: ${response.statusCode} ${response.data['error']}');
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
    final response = await _get('/admin/students');
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
    if (response.statusCode != 200) {
      throw Exception('Failed to delete student: ${response.statusCode} ${response.data['error']}');
    }
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _put('/admin/users/$id', data);
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
      throw Exception('Unexpected status: ${response.statusCode}');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? 'Unknown error updating user.';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
  

 // ------------------------------
// 🔹 Import / Export
// ------------------------------
static Future<void> importStudents(List<Map<String, dynamic>> students, {required BuildContext context}) async {
  try {
    final response = await _post('/admin/import', {'students': students});
    if (response.statusCode == 200 || response.statusCode == 207) {
      final data = response.data as Map<String, dynamic>;
      final importedCount = data['importedStudents'] as int? ?? 0;
      final errors = data['errors'] as List<dynamic>? ?? [];

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Импортировано $importedCount студентов${errors.isNotEmpty ? ', с ${errors.length} ошибками' : ''}'),
          ),
        );
      }

      if (errors.isNotEmpty) {
        print('Import completed with errors: $errors');
      }
    } else {
      throw Exception('Failed to import students: ${response.data['error'] ?? 'Unknown error'}');
    }
  } on DioException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сетевая ошибка импорта: ${e.response?.data['error'] ?? e.message}')),
      );
    }
    throw Exception('Network error during import: ${e.response?.data['error'] ?? e.message}');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
    }
    throw Exception('Unexpected error during import: $e');
  }
}

static Future<void> exportExcel({
  String? startDate,
  String? endDate,
  String? groupId,
  required BuildContext context,
}) async {
  final query = <String, dynamic>{};
  if (startDate != null) query['startDate'] = startDate;
  if (endDate != null) query['endDate'] = endDate;
  if (groupId != null) query['groupId'] = groupId;

  try {
    final response = await _dio.get(
      '/export/excel',
      queryParameters: query.isNotEmpty ? query : null,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200) {
      final bytes = response.data as List<int>;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/exported_attendance.xlsx');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel файл успешно сохранён во временную директорию')),
        );
      }
    } else {
      throw Exception('Failed to export Excel: ${response.data['error']}');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта Excel: $e')),
      );
    }
    throw Exception('Error exporting Excel: $e');
  }
}
} 