import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/subject.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart'; // NEW

class GroupsProvider with ChangeNotifier {
  List<Group> _groups = [];
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // NEW: Проверяем кэш
    final cachedGroups = HiveService.getGroups();
    if (cachedGroups != null) {
      _groups = cachedGroups;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await ApiService.getGroups();
      _groups = data.map((json) => Group.fromJson(json)).toList();
      await HiveService.saveGroups(_groups); // Сохраняем в кэш
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubjects() async {
    // NEW: Проверяем кэш
    final cachedSubjects = HiveService.getSubjects();
    if (cachedSubjects != null) {
      _subjects = cachedSubjects;
      notifyListeners();
      return;
    }

    try {
      final data = await ApiService.getSubjects();
      _subjects = data.map((json) => Subject.fromJson(json)).toList();
      await HiveService.saveSubjects(_subjects); // Сохраняем
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}