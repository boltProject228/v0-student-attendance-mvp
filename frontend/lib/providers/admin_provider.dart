  import 'package:flutter/material.dart';
  import '../models/user.dart';
  import '../models/group.dart';
  import '../models/student.dart';
  import '../services/api_service.dart';

  class AdminProvider with ChangeNotifier {
    List<User> _users = [];
    List<Group> _groups = [];
    List<Student> _students = [];

    bool _isLoading = false;
    String? _error;

    List<User> get users => _users;
    List<Group> get groups => _groups;
    List<Student> get students => _students;

    bool get isLoading => _isLoading;
    String? get error => _error;

    Future<void> fetchUsers() async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final data = await ApiService.getAdminUsers();
        _users = data.map((json) => User.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load users: $e';
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<bool> createUser(Map<String, dynamic> data) async {
      try {
        await ApiService.createUser(data);
        await fetchUsers();
        return true;
      } catch (e) {
        _error = 'Failed to create user: $e';
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteUser(String id) async {
      try {
        await ApiService.deleteUser(id);
        await fetchUsers();
        return true;
      } catch (e) {
        _error = 'Failed to delete user: $e';
        notifyListeners();
        return false;
      }
    }

    Future<void> fetchGroups() async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final data = await ApiService.getAdminGroups();
        _groups = data;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load groups: $e';
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<bool> createGroup(Map<String, dynamic> data) async {
      try {
        await ApiService.createGroup(data);
        await fetchGroups();
        return true;
      } catch (e) {
        _error = 'Failed to create group: $e';
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteGroup(String id) async {
      try {
        await ApiService.deleteGroup(id);
        await fetchGroups();
        return true;
      } catch (e) {
        _error = 'Failed to delete group: $e';
        notifyListeners();
        return false;
      }
    }

    Future<void> fetchStudents() async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final data = await ApiService.getAdminStudents();
        print('Fetched students data: $data'); // Отладка
        _students = data.map((json) => Student.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load students: $e';
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<bool> createStudent(Map<String, dynamic> data) async {
      try {
        await ApiService.createStudent(data);
        await fetchStudents();
        return true;
      } catch (e) {
        _error = 'Failed to create student: $e';
        notifyListeners();
        return false;
      }
    }

    Future<bool> deleteStudent(String id) async {
      try {
        await ApiService.deleteStudent(id);
        await fetchStudents();
        return true;
      } catch (e) {
        _error = 'Failed to delete student: $e';
        notifyListeners();
        return false;
      }
    }

    Future<bool> updateUser(String id, Map<String, dynamic> data) async {
      try {
        await ApiService.updateUser(id, data);
        await fetchUsers();
        return true;
      } catch (e) {
        _error = 'Failed to update user: $e';
        notifyListeners();
        return false;
      }
    }

    Future<bool> importStudents(List<Map<String, dynamic>> students, {required BuildContext context}) async {
      try {
        await ApiService.importStudents(students, context: context);
        await fetchStudents(); // Обновление данных после импорта
        _error = null; // Сбрасываем ошибку при успехе
        notifyListeners();
        return true;
      } catch (e) {
        _error = 'Failed to import students: $e';
        notifyListeners();
        return false;
      }
    }
  }