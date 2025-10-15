import 'package:attendance_system/models/user.dart';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  static const bool useMock = true;

  Future<bool> login(String login, String password, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> response;
      if (useMock) {
        response = MockData.mockLogin(login, password);
      } else {
        response = await ApiService.login(login, password);
      }

      final token = response['token'];
      final userData = response['user'];

      await HiveService.saveToken(token);
      final user = User.fromJson(userData);
      await HiveService.saveUser(user);

      _user = user;
      _isLoading = false;
      notifyListeners();

      // 📥 Загрузка мок-данных
      if (useMock) {
        try {
          await _loadMockData();
        } catch (e) {
          print('Failed to load mock data: $e');
          _error = 'Ошибка загрузки данных: $e';
          notifyListeners();
        }
      }

      // 🔀 Перенаправление по роли
      if (user.isTeacher) {
        Navigator.pushReplacementNamed(context, '/teacher_home');
      } else if (user.isHead) {
        Navigator.pushReplacementNamed(context, '/head_home');
      } else {
        _error = 'Неизвестная роль пользователя';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Login error: $e');
      return false;
    }
  }

  Future<void> _loadMockData() async {
    print('📊 Загрузка моковых данных...');
    final groups = MockData.mockGetGroups();
    await HiveService.saveGroups(groups);

    final students = MockData.mockGetStudents();
    await HiveService.saveStudents(students);

    final attendance = MockData.mockGetAttendance();
    await HiveService.saveAttendance(attendance);

    print('✅ Моковые данные успешно загружены');
  }

  Future<void> logout() async {
    try {
      if (!useMock) {
        await ApiService.logout();
      }
    } catch (e) {
      print('Logout error: $e');
    }
    await HiveService.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    final token = HiveService.getToken();
    if (token == null) return false;

    final cachedUser = HiveService.getUser();
    if (cachedUser != null) {
      _user = cachedUser;
      notifyListeners();
      return true;
    }

    try {
      Map<String, dynamic> userData;
      if (useMock) {
        userData = {
          'id': 'mock',
          'login': 'mock_user',
          'role': 'teacher',
          'fullName': 'Моковый Преподаватель',
          'createdAt': DateTime.now().toIso8601String(),
        };
      } else {
        userData = await ApiService.getCurrentUser();
      }

      final user = User.fromJson(userData);
      await HiveService.saveUser(user);
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      await HiveService.clearAll();
      return false;
    }
  }
}
