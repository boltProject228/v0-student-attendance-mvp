// lib/providers/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/user.dart';
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

  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isHead => _user?.isHead ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<bool> login(String login, String password, BuildContext context) async {
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

      switch (user.role) {
        case 'teacher':
          Navigator.pushReplacementNamed(context, '/teacher_home');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'head':
          Navigator.pushReplacementNamed(context, '/head_home');
          break;
        default:
          _error = 'Неизвестная роль пользователя: ${user.role}';
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

  Future<void> logout() async {
    try {
      await ApiService.logout();
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
