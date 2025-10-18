import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class AnalyticsProvider with ChangeNotifier {
  Map<String, dynamic>? _groupAnalytics;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get groupAnalytics => _groupAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroupAnalytics({
    required String groupId,
    required String startDate,
    required String endDate,
    String period = 'day',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check cache
    final cacheKey = 'analytics_${groupId}_${startDate}_${endDate}_${period}';
    final cachedData = HiveService.getGeneric<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      _groupAnalytics = cachedData;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService.getGroupAnalytics(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );
      _groupAnalytics = response;
      await HiveService.saveGeneric(cacheKey, response, const Duration(hours: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Analytics fetch error: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAnalytics() {
    _groupAnalytics = null;
    _error = null;
    notifyListeners();
  }
}