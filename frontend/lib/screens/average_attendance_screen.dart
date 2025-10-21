import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/groups_provider.dart';
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';
import 'package:attendance_system/screens/analytics/widgets/date_filter_bar.dart';
import 'package:attendance_system/screens/analytics/logic/date_ranges.dart';
import 'package:attendance_system/screens/analytics/models/academic_range.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AverageAttendanceScreen extends StatefulWidget {
  const AverageAttendanceScreen({super.key});

  @override
  State<AverageAttendanceScreen> createState() => _AverageAttendanceScreenState();
}

class _AverageAttendanceScreenState extends State<AverageAttendanceScreen> {
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  DateTime? _selectedDate;
  DateTime? _endDate;
  bool _isRange = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final attendanceProvider = context.read<AttendanceProvider>();
    final groupsProvider = context.read<GroupsProvider>();

    await attendanceProvider.fetchAttendance();
    await attendanceProvider.fetchStudents();
    await groupsProvider.fetchGroups();

    final start = _selectedDate ?? DateTime.now();
    final end = _isRange ? (_endDate ?? start) : start;
    final dates = _generateDateRange(start, end);
    final numDays = dates.length.toDouble();

    double present = 0, absent = 0, sick = 0, ithub = 0;
    int totalRecords = 0;
    int totalStudents = attendanceProvider.students.length;

    for (var group in groupsProvider.groups) {
      for (var date in dates) {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
        present += stats['present']?.toDouble() ?? 0.0;
        absent += stats['absent']?.toDouble() ?? 0.0;
        sick += stats['sick']?.toDouble() ?? 0.0;
        ithub += stats['ithub']?.toDouble() ?? 0.0;
        totalRecords += (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['sick'] ?? 0) + (stats['ithub'] ?? 0);
      }
    }

    // Средние значения за день в режиме диапазона
    final double avgPresent = _isRange ? present / numDays : present;
    final double avgAbsent = _isRange ? absent / numDays : absent;
    final double avgSick = _isRange ? sick / numDays : sick;
    final double avgIthub = _isRange ? ithub / numDays : ithub;
    final double avgTotalRecords = _isRange ? totalRecords.toDouble() / numDays : totalRecords.toDouble();

    // Базис для процентов — общее количество отметок
    final double total = avgTotalRecords > 0 ? avgTotalRecords : 1.0;

    if (mounted) {
      setState(() {
        _analyticsData = {
          'averagePresent': ((avgPresent / total) * 100).clamp(0.0, 100.0).toStringAsFixed(1),
          'averageAbsent': ((avgAbsent / total) * 100).clamp(0.0, 100.0).toStringAsFixed(1),
          'averageSick': ((avgSick / total) * 100).clamp(0.0, 100.0).toStringAsFixed(1),
          'averageIThub': ((avgIthub / total) * 100).clamp(0.0, 100.0).toStringAsFixed(1),
          'countPresent': avgPresent,
          'countAbsent': avgAbsent,
          'countSick': avgSick,
          'countIThub': avgIthub,
          'totalRecords': avgTotalRecords,
          'totalStudents': totalStudents,
          'numDays': dates.length,
        };
        _isLoading = false;
      });
    }
  }

  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    for (var date = startDay; date.isBefore(endDay.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
        dates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    }
    return dates;
  }

  Future<void> _setFilterRange({
    AcademicRange? fixedRange,
    DateTime? manualStart,
    DateTime? manualEnd,
  }) async {
    DateTime newStartDate;
    DateTime? newEndDate;
    bool newIsRange = false;

    if (fixedRange != null) {
      newStartDate = fixedRange.startDate;
      newEndDate = fixedRange.endDate;
      newIsRange = fixedRange.endDate != null;
    } else if (manualStart != null) {
      newStartDate = manualStart;
      newEndDate = manualEnd;
      newIsRange = manualEnd != null;
    } else {
      newStartDate = DateTime.now();
      newEndDate = null;
      newIsRange = false;
    }

    setState(() {
      _selectedDate = newStartDate;
      _endDate = newEndDate;
      _isRange = newIsRange;
    });

    await _loadAnalytics();
  }

  Widget _buildLegendItem(String label, Color color, String value, double count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              children: <TextSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: '$value% ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
                ),
                if (!_isRange && count > 0)
                  TextSpan(
                    text: ' | ${count.round()} студентов',
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    final data = _analyticsData!;
    final double present = double.parse(data['averagePresent']);
    final double absent = double.parse(data['averageAbsent']);
    final double sick = double.parse(data['averageSick']);
    final double ithub = double.parse(data['averageIThub']);
    final int numDays = data['numDays'];
    final int totalStudents = data['totalStudents'];

    final totalValue = present + absent + sick + ithub;

    if (totalValue == 0) {
      return Card(
        elevation: 6,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'Нет отметок за выбранный период (${_isRange ? 'с ${DateFormat('dd.MM').format(_selectedDate!)} по ${DateFormat('dd.MM').format(_endDate ?? _selectedDate!)}' : DateFormat('dd.MM.yyyy').format(_selectedDate!)}).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    String getTitle(double value) {
      return value > 3.0 ? '${value.toStringAsFixed(0)}%' : '';
    }

    final sections = [
      PieChartSectionData(
        color: Colors.green.shade600,
        value: present,
        title: getTitle(present),
        radius: 70,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red.shade600,
        value: absent,
        title: getTitle(absent),
        radius: 70,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange.shade600,
        value: sick,
        title: getTitle(sick),
        radius: 70,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.purple.shade600,
        value: ithub,
        title: getTitle(ithub),
        radius: 70,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return Card(
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRange
                  ? 'Среднее распределение отметок за день ($numDays дн.)'
                  : 'Распределение отметок ($totalStudents студентов)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 250,
                width: 250,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 4,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children: [
                _buildLegendItem(
                  'Присутствовали',
                  Colors.green.shade600,
                  data['averagePresent'],
                  _isRange ? 0 : data['countPresent'],
                ),
                _buildLegendItem(
                  'Отсутствовали',
                  Colors.red.shade600,
                  data['averageAbsent'],
                  _isRange ? 0 : data['countAbsent'],
                ),
                _buildLegendItem(
                  'Больничные',
                  Colors.orange.shade600,
                  data['averageSick'],
                  _isRange ? 0 : data['countSick'],
                ),
                _buildLegendItem(
                  'IT-hub',
                  Colors.purple.shade600,
                  data['averageIThub'],
                  _isRange ? 0 : data['countIthub'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final double titleFontSize = isMobile ? 17.0 : 20.0;

    final authProvider = context.watch<AuthProvider>();
    Widget? drawerWidget;
    if (authProvider.isHead) {
      drawerWidget = const HeadHomeDrawer();
    } else if (authProvider.isAdmin) {
      drawerWidget = const AdminHomeDrawer();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Средняя посещаемость',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAnalytics,
          ),
        ],
      ),
      drawer: drawerWidget,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
              ? const Center(child: Text('Нет данных для отображения', style: TextStyle(fontSize: 18)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DateFilterBar(
                        isMobile: isMobile,
                        startDate: _selectedDate,
                        endDate: _endDate,
                        isRange: _isRange,
                        fixedRanges: generateFixedRanges(),
                        onFixedRangeSelected: (range) => _setFilterRange(fixedRange: range),
                        onManualRangeSelected: (start, end) => _setFilterRange(manualStart: start, manualEnd: end),
                      ),
                      const SizedBox(height: 24),
                      _buildChartCard(context),
                    ],
                  ),
                ),
    );
  }
}