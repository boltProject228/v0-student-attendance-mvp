import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/groups_provider.dart';
import 'package:attendance_system/providers/auth_provider.dart'; // ❗ ДОБАВИТЬ: Импорт AuthProvider
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _isRange = false;
  DateTime? _endDate;

  // ❌ УДАЛЕНО: Ошибочный код, использующий context вне build:
  // Widget? drawerWidget;
  // if (authProvider.isHead) {
  //   drawerWidget = const HeadHomeDrawer();
  // } else if (authProvider.isAdmin) {
  //   drawerWidget = const AdminHomeDrawer();
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    // Используем `read` для провайдеров
    // Примечание: AuthProvider здесь не нужен, но если бы он был нужен, 
    // его тоже можно было бы получить через context.read<AuthProvider>()
    final attendanceProvider = context.read<AttendanceProvider>();
    final groupsProvider = context.read<GroupsProvider>();

    await attendanceProvider.fetchAttendance();
    await attendanceProvider.fetchStudents();
    await groupsProvider.fetchGroups();

    final start = _selectedDate;
    final end = _isRange ? _endDate ?? _selectedDate : _selectedDate;

    double present = 0, absent = 0, sick = 0, ithub = 0;
    int totalRecords = 0;

    final dates = _generateDateRange(start, end);

    for (var group in groupsProvider.groups) {
      for (var date in dates) {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
        present += stats['present'] ?? 0;
        absent += stats['absent'] ?? 0;
        sick += stats['sick'] ?? 0;
        ithub += stats['ithub'] ?? 0;
        
        totalRecords += (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['sick'] ?? 0) + (stats['ithub'] ?? 0);
      }
    }

    final total = totalRecords > 0 ? totalRecords.toDouble() : 1.0; 

    if (mounted) {
      setState(() {
        _analyticsData = {
          'averagePresent': (present / total * 100).toStringAsFixed(1),
          'averageAbsent': (absent / total * 100).toStringAsFixed(1),
          'averageSick': (sick / total * 100).toStringAsFixed(1),
          'averageIThub': (ithub / total * 100).toStringAsFixed(1),
          'countPresent': present.toInt(),
          'countAbsent': absent.toInt(),
          'countSick': sick.toInt(),
          'countIThub': ithub.toInt(),
          'totalRecords': totalRecords,
        };
        _isLoading = false;
      });
    }
  }

  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    
    for (var date = startDay;
        date.isBefore(endDay.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return dates;
  }

  Widget _buildLegendItem(String label, Color color, String value, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
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
                TextSpan(
                  text: '| $count студентов',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 20),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                _isRange
                    ? '${DateFormat('dd.MM.yyyy').format(_selectedDate)} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выберите дату'}'
                    : DateFormat('dd.MM.yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            onPressed: () async {
              if (_isRange) {
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: _endDate != null ? DateTimeRange(start: _selectedDate, end: _endDate!) : null,
                );
                if (pickedRange != null) {
                  setState(() {
                    _selectedDate = pickedRange.start;
                    _endDate = pickedRange.end;
                  });
                  _loadAnalytics();
                }
              } else {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _endDate = null;
                  });
                  _loadAnalytics();
                }
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch.adaptive(
              value: _isRange,
              onChanged: (value) {
                setState(() {
                  _isRange = value;
                  if (!value) _endDate = null;
                });
                _loadAnalytics();
              },
            ),
            const Text('Диапазон', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context) {
    final data = _analyticsData!;
    final double present = double.parse(data['averagePresent']);
    final double absent = double.parse(data['averageAbsent']);
    final double sick = double.parse(data['averageSick']);
    final double ithub = double.parse(data['averageIThub']);
    final int totalRecords = data['totalRecords'];

    final totalValue = present + absent + sick + ithub;

    if (totalRecords == 0 || totalValue == 0) {
      return Card(
        elevation: 6,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'Нет отметок за выбранный период (${_isRange ? 'c ${DateFormat('dd.MM').format(_selectedDate)} по ${DateFormat('dd.MM').format(_endDate ?? _selectedDate)}' : DateFormat('dd.MM.yyyy').format(_selectedDate)}).', 
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
              'Распределение отметок (Всего отметок: $totalRecords)',
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
                  'Присутствовали', Colors.green.shade600, data['averagePresent'], data['countPresent']
                ),
                _buildLegendItem(
                  'Отсутствовали', Colors.red.shade600, data['averageAbsent'], data['countAbsent']
                ),
                _buildLegendItem(
                  'Больничные', Colors.orange.shade600, data['averageSick'], data['countSick']
                ),
                _buildLegendItem(
                  'IT-hub', Colors.purple.shade600, data['averageIThub'], data['countIThub']
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
    // ❗ ИСПРАВЛЕНИЕ 1: Адаптивная логика перемещена внутрь build
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final double titleFontSize = isMobile ? 17.0 : 20.0;

    // ❗ ИСПРАВЛЕНИЕ 2: Получаем AuthProvider и логику drawer
    // Используем context.watch<T>() для отслеживания изменений в провайдере
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
      // ❗ ПРИМЕНЕНИЕ: Используем вычисленный drawerWidget
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
                      _buildDateFilter(),
                      const SizedBox(height: 24),
                      _buildChartCard(context),
                    ],
                  ),
                ),
    );
  }
}