import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class GroupsProvider with ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedGroups = HiveService.getGroups();
      if (cachedGroups != null) {
        _groups = cachedGroups;
        print('Loaded ${cachedGroups.length} groups from cache');
        notifyListeners();
      }

      final data = await ApiService.getGroups();
      print('Raw API response for groups: ${data.map((g) => g.toJson()).toList()}'); // Логируем JSON
      _groups = data;
      await HiveService.saveGroups(_groups);
      print('Saved ${_groups.length} groups to Hive');
    } catch (e) {
      _error = e.toString();
      print('GroupsProvider fetch error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}