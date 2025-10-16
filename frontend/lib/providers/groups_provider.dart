// lib/providers/groups_provider.dart
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
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      await HiveService.saveGroups(_groups);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}