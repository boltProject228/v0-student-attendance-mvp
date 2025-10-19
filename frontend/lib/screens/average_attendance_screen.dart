import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/groups_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);

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
        totalRecords += stats['marked'] ?? 0;
      }
    }

    final total = totalRecords > 0 ? totalRecords : 1;

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
      };
      _isLoading = false;
    });
  }

  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    for (var date = start;
        date.isBefore(end.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return dates;
  }

  Widget _buildLegendItem(String label, Color color, String value, int count) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label: $value% ($count)'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Средняя посещаемость'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
              ? const Center(child: Text('Нет данных'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDateFilter(),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 250,
                            child: Stack(
                              children: [
                                PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        color: Colors.green,
                                        value: double.parse(_analyticsData!['averagePresent']),
                                        title: '',
                                      ),
                                      PieChartSectionData(
                                        color: Colors.red,
                                        value: double.parse(_analyticsData!['averageAbsent']),
                                        title: '',
                                      ),
                                      PieChartSectionData(
                                        color: Colors.orange,
                                        value: double.parse(_analyticsData!['averageSick']),
                                        title: '',
                                      ),
                                      PieChartSectionData(
                                        color: Colors.purple,
                                        value: double.parse(_analyticsData!['averageIThub']),
                                        title: '',
                                      ),
                                    ],
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendItem(
                                        'Присутствовали',
                                        Colors.green,
                                        _analyticsData!['averagePresent'],
                                        _analyticsData!['countPresent'],
                                      ),
                                      _buildLegendItem(
                                        'Отсутствовали',
                                        Colors.red,
                                        _analyticsData!['averageAbsent'],
                                        _analyticsData!['countAbsent'],
                                      ),
                                      _buildLegendItem(
                                        'Больничные',
                                        Colors.orange,
                                        _analyticsData!['averageSick'],
                                        _analyticsData!['countSick'],
                                      ),
                                      _buildLegendItem(
                                        'IT-hub',
                                        Colors.purple,
                                        _analyticsData!['averageIThub'],
                                        _analyticsData!['countIThub'],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 20),
            label: Text(
              _isRange
                  ? '${DateFormat('dd.MM.yyyy').format(_selectedDate)} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выберите'}'
                  : DateFormat('dd.MM.yyyy').format(_selectedDate),
            ),
            onPressed: () async {
              if (_isRange) {
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
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
                  setState(() => _selectedDate = picked);
                  _loadAnalytics();
                }
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: _isRange,
          onChanged: (value) {
            setState(() {
              _isRange = value;
              if (!value) _endDate = null;
            });
            _loadAnalytics();
          },
        ),
        const Text('Диапазон'),
      ],
    );
  }
}
