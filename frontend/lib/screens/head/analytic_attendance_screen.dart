import 'package:attendance_system/models/group.dart';
import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/analytics_provider.dart';
import 'package:attendance_system/widgets/analytic_summary_bar.dart';
import 'package:attendance_system/widgets/analytics_attendance_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnalyticAttendanceScreen extends StatefulWidget {
  final Group group;

  const AnalyticAttendanceScreen({super.key, required this.group});

  @override
  State<AnalyticAttendanceScreen> createState() => _AnalyticAttendanceScreenState();
}

class _AnalyticAttendanceScreenState extends State<AnalyticAttendanceScreen> {
  String _selectedPeriod = 'day';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchStudents();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);
    await analyticsProvider.fetchGroupAnalytics(
      groupId: widget.group.id,
      startDate: startDateStr,
      endDate: endDateStr,
      period: _selectedPeriod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final students = attendanceProvider.students.where((s) => s.groupId == widget.group.id).toList();
    final studentCount = students.length;
    final groupAnalytics = analyticsProvider.groupAnalytics;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Группа ${widget.group.name}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  'Всего в группе: $studentCount',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    items: [
                      DropdownMenuItem(value: 'day', child: Text('По дням')),
                      DropdownMenuItem(value: 'week', child: Text('По неделям')),
                      DropdownMenuItem(value: 'month', child: const Text('По месяцам')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPeriod = value);
                        _loadAnalytics();
                      }
                    },
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: Text(
                    '${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final pickedRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (pickedRange != null) {
                      setState(() {
                        _startDate = pickedRange.start;
                        _endDate = pickedRange.end;
                      });
                      _loadAnalytics();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analyticsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (analyticsProvider.error != null)
              Center(child: Text('Ошибка: ${analyticsProvider.error}'))
            else if (groupAnalytics != null) ...[
              Text(
                'Посещаемость группы: ${groupAnalytics['groupPercentage']}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: double.parse(groupAnalytics['groupPercentage']) > 80
                      ? Colors.green
                      : double.parse(groupAnalytics['groupPercentage']) >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final studentAnalytics = groupAnalytics['students'].firstWhere(
                      (s) => s['studentId'] == student.id,
                      orElse: () => {
                        'studentId': student.id,
                        'fullName': student.fullName,
                        'attendancePercentage': '0',
                        'periods': []
                      },
                    );
                    final today = DateTime.now().toIso8601String().split('T')[0];
                    final status = attendanceProvider.getStudentAttendance(student.id, today).status;

                    return AnalyticsAttendanceTile(
                      index: index + 1,
                      name: student.fullName,
                      status: status,
                      attendancePercentage: double.parse(studentAnalytics['attendancePercentage']),
                      statusSequence: studentAnalytics['periods'].isNotEmpty
                          ? studentAnalytics['periods'][0]['statuses']
                          : [],
                      onStatusChange: null, // Read-only
                    );
                  },
                ),
              ),
              AnalyticSummaryBar(
                present: groupAnalytics['students'].fold<int>(0, (sum, s) => sum + (s['periods'].isNotEmpty && s['periods'][0]['statuses'].contains('present') ? 1 : 0)),
                absent: groupAnalytics['students'].fold<int>(0, (sum, s) => sum + (s['periods'].isNotEmpty && s['periods'][0]['statuses'].contains('absent') ? 1 : 0)),
                sick: groupAnalytics['students'].fold<int>(0, (sum, s) => sum + (s['periods'].isNotEmpty && s['periods'][0]['statuses'].contains('sick') ? 1 : 0)),
                ithub: groupAnalytics['students'].fold<int>(0, (sum, s) => sum + (s['periods'].isNotEmpty && s['periods'][0]['statuses'].contains('ithub') ? 1 : 0)),
                unmarked: groupAnalytics['students'].fold<int>(0, (sum, s) => sum + (s['periods'].isNotEmpty && s['periods'][0]['statuses'].contains('unmarked') ? 1 : 0))    
                ,
                onSave: null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}