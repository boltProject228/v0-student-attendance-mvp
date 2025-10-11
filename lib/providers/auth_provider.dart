import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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

      await StorageService.saveToken(token);
      await StorageService.saveUserData(jsonEncode(userData));

      _user = User.fromJson(userData);
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

    await StorageService.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> checkAuth() async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    try {
      final userData = await ApiService.getCurrentUser();
      _user = User.fromJson(userData);
      notifyListeners();
      return true;
    } catch (e) {
      await StorageService.clearAll();
      return false;
    }
  }
}
