import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart'; // NEW: Замена storage

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String login, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(login, password);
      final token = response['token'];
      final userData = response['user'];

      await HiveService.saveToken(token);
      final user = User.fromJson(userData);
      await HiveService.saveUser(user);

      _user = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout API error: $e');
    }

    await HiveService.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    final token = HiveService.getToken();
    if (token == null) return false;

    // NEW: Сначала пробуем из Hive
    final cachedUser = HiveService.getUser();
    if (cachedUser != null) {
      _user = cachedUser;
      notifyListeners();
      return true;
    }

    // Если нет в кэше — с сервера
    try {
      final userData = await ApiService.getCurrentUser();
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