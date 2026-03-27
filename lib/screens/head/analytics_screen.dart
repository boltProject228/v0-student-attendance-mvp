import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/screens/head/analytic_attendance_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/head/head_home_drawer.dart';
import '../../models/group.dart';
import '../../widgets/analytic_group_card.dart'; // Изменено на GroupCard для идентичности с Home

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum SortOrder { ascending, descending }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _groupAnalytics = [];
  List<Map<String, dynamic>> _studentAnalytics = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = false;

  SortOrder _studentSortOrder = SortOrder.descending;

  // Фильтры для групп
  String _searchQuery = '';
  String _selectedSpecialty = 'Все';
  String _selectedCourse = 'Все';

  final List<String> _specialties = [
    'Все',
    'ПО',
    'СИБ',
    'М(Ру)',
    'ТЭ(Ру)',
    'БҚЕ',
    'АҚЖ',
    'М(Қаз)',
    'ТЭ(Қаз)',
  ];

  final List<String> _courses = ['Все', '1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);

      await attendanceProvider.fetchStudents();
      await attendanceProvider.fetchAttendance();
      await groupsProvider.fetchGroups();

      final overallAnalytics = await _calculateOverallAnalytics(attendanceProvider, groupsProvider);
      final groupAnalytics = await _calculateGroupAnalytics(attendanceProvider, groupsProvider);
      final studentAnalytics = await _calculateStudentAnalytics(attendanceProvider);

      setState(() {
        _analyticsData = overallAnalytics;
        _groupAnalytics = groupAnalytics;
        _studentAnalytics = _sortAnalytics(studentAnalytics, _studentSortOrder);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить данные аналитики'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _sortAnalytics(List<Map<String, dynamic>> data, SortOrder order) {
    data.sort((a, b) {
      final aVal = double.parse(a['percent']);
      final bVal = double.parse(b['percent']);
      return order == SortOrder.ascending
          ? aVal.compareTo(bVal)
          : bVal.compareTo(aVal);
    });
    return data;
  }

  Future<Map<String, dynamic>> _calculateOverallAnalytics(
    AttendanceProvider attendanceProvider,
    GroupsProvider groupsProvider,
  ) async {
    final totalStudents = attendanceProvider.students.length;
    final totalGroups = groupsProvider.groups.length;

    double present = 0, absent = 0, sick = 0, ithub = 0;
    int totalRecords = 0;

    final start = _isRange ? _startDate : _startDate;
    final end = _isRange ? _endDate : _startDate;

    for (var group in groupsProvider.groups) {
      final dates = _isRange
          ? _generateDateRange(start!, end!)
          : [DateFormat('yyyy-MM-dd').format(start!)];
      for (var date in dates) {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
        present += stats['present']?.toDouble() ?? 0;
        absent += stats['absent']?.toDouble() ?? 0;
        sick += stats['sick']?.toDouble() ?? 0;
        ithub += stats['ithub']?.toDouble() ?? 0;
        totalRecords += stats['marked'] ?? 0;
      }
    }

    final total = totalRecords > 0 ? totalRecords : 1;
    return {
      'totalStudents': totalStudents,
      'totalGroups': totalGroups,
      'averagePresent': (present / total * 100).toStringAsFixed(1),
      'averageAbsent': (absent / total * 100).toStringAsFixed(1),
      'averageSick': (sick / total * 100).toStringAsFixed(1),
      'averageIThub': (ithub / total * 100).toStringAsFixed(1),
    };
  }

  Future<List<Map<String, dynamic>>> _calculateGroupAnalytics(
    AttendanceProvider attendanceProvider,
    GroupsProvider groupsProvider,
  ) async {
    final start = _isRange ? _startDate : _startDate;
    final end = _isRange ? _endDate : _startDate;
    final dates = _isRange
        ? _generateDateRange(start!, end!)
        : [DateFormat('yyyy-MM-dd').format(start!)];

    List<Map<String, dynamic>> groupData = [];
    for (var group in groupsProvider.groups) {
      double present = 0;
      int totalRecords = 0;
      int studentCount = attendanceProvider.getGroupStudentCount(group.id);
      for (var date in dates) {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
        present += stats['present']?.toDouble() ?? 0;
        totalRecords += stats['marked'] ?? 0;
      }
      final total = totalRecords > 0 ? totalRecords : 1;
      final percent = (present / total * 100).toStringAsFixed(1);
      groupData.add({
        'groupId': group.id,
        'name': group.name,
        'specialty': group.specialty,
        'course': group.course,
        'percent': percent,
        'studentCount': studentCount,
      });
    }

    return groupData;
  }

  Future<List<Map<String, dynamic>>> _calculateStudentAnalytics(
    AttendanceProvider attendanceProvider,
  ) async {
    final start = _isRange ? _startDate : _startDate;
    final end = _isRange ? _endDate : _startDate;
    final dates = _isRange
        ? _generateDateRange(start!, end!)
        : [DateFormat('yyyy-MM-dd').format(start!)];

    List<Map<String, dynamic>> studentData = [];
    for (var student in attendanceProvider.students) {
      double present = 0;
      int totalRecords = 0;
      for (var date in dates) {
        final attendance = attendanceProvider.getStudentAttendance(student.id, date);
        if (attendance.status != 'unmarked') {
          totalRecords++;
          if (attendance.isPresent) present++;
        }
      }
      final total = totalRecords > 0 ? totalRecords : 1;
      final percent = (present / total * 100).toStringAsFixed(1);
      studentData.add({
        'studentId': student.id,
        'fullName': student.fullName,
        'percent': percent,
      });
    }

    return studentData;
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

  String normalize(String input) {
    String normalized = input.toUpperCase();
    const map = {
      'Қ': 'К',
      'Ә': 'А',
      'Ө': 'О',
      'Ұ': 'У',
      'Ғ': 'Г',
      'Ң': 'Н',
      'І': 'И',
    };
    map.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    return normalized.trim();
  }

  List<Group> _filteredGroups(
    List<Map<String, dynamic>> analytics,
    List<Group> allGroups,
    List<Student> students,
  ) {
    final normalizedQuery = normalize(_searchQuery);
    final filteredAnalytics = analytics.where((data) {
      final groupName = normalize(data['name']);
      final specialty = normalize(data['specialty']);
      final courseStr = data['course'].toString();

      final matchesSearch = groupName.contains(normalizedQuery) ||
          students.any((s) => s.groupId == data['groupId'] && normalize(s.fullName).contains(normalizedQuery));
      final matchesCourse = _selectedCourse == 'Все' || courseStr == _selectedCourse;
      final matchesSpecialty = _selectedSpecialty == 'Все' || specialty.contains(normalize(_selectedSpecialty));

      return matchesSearch && matchesCourse && matchesSpecialty;
    }).map((data) => data['groupId']).toSet();

    return allGroups.where((group) => filteredAnalytics.contains(group.id)).toList();
  }

  Color _getPercentColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final filteredGroups = _filteredGroups(_groupAnalytics, groupsProvider.groups, attendanceProvider.students);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dateStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика посещаемости'),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      drawer: const HeadHomeDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _isLoading
            ? _buildSkeletonLoader()
            : _analyticsData == null
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateFilter(),
                        const SizedBox(height: 24),
                        _buildAverageChart(),
                        const SizedBox(height: 24),
                        const Text('Аналитика по группам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
                        _buildGroupFilters(isMobile),
                        const SizedBox(height: 16),
                        _buildGroupAnalytics(filteredGroups, attendanceProvider, dateStr),
                        const SizedBox(height: 24),
                        _buildStudentAnalytics(),
                      ],
                    ),
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
                  ? '${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Выберите'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выберите'}'
                  : _startDate != null
                      ? DateFormat('dd.MM.yyyy').format(_startDate!)
                      : 'Выберите дату',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
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
                    _startDate = pickedRange.start;
                    _endDate = pickedRange.end;
                  });
                  _loadAnalytics();
                }
              } else {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
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

  Widget _buildAverageChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Средняя посещаемость', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
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
                        PieChartSectionData(color: Colors.green, value: double.parse(_analyticsData!['averagePresent']), title: ''),
                        PieChartSectionData(color: Colors.red, value: double.parse(_analyticsData!['averageAbsent']), title: ''),
                        PieChartSectionData(color: Colors.orange, value: double.parse(_analyticsData!['averageSick']), title: ''),
                        PieChartSectionData(color: Colors.purple, value: double.parse(_analyticsData!['averageIThub']), title: ''),
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
                        _buildLegendItem('Присутствовали', Colors.green, _analyticsData!['averagePresent']),
                        _buildLegendItem('Отсутствовали', Colors.red, _analyticsData!['averageAbsent']),
                        _buildLegendItem('Больничные', Colors.orange, _analyticsData!['averageSick']),
                        _buildLegendItem('IT-hub', Colors.purple, _analyticsData!['averageIThub']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupFilters(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Поиск по группе или студенту',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => setState(() {
                  _selectedSpecialty = value!;
                  _selectedCourse = 'Все';
                }),
                decoration: InputDecoration(
                  labelText: 'Специальность',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCourse,
                items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCourse = value!),
                decoration: InputDecoration(
                  labelText: 'Курс',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupAnalytics(
    List<Group> filteredGroups,
    AttendanceProvider attendanceProvider,
    String dateStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        filteredGroups.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Группы не найдены',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 1;

                  if (width > 1200) {
                    crossAxisCount = 3;
                  } else if (width > 800) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 32,
                      mainAxisExtent: 260,
                    ),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      final studentCount = attendanceProvider.getGroupStudentCount(group.id);
                      final stats = attendanceProvider.getGroupAttendanceStats(group.id, dateStr);

                      return AnalyticGroupCard(
                        group: group,
                        studentCount: studentCount,
                        markedCount: stats['marked'] ?? 0,
                        presentCount: stats['present'] ?? 0,
                        absentCount: stats['absent'] ?? 0,
                        sickCount: stats['sick'] ?? 0,
                        ithubCount: stats['ithub'] ?? 0,
                        onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticAttendanceScreen(group: group)));},
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildStudentAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Аналитика по студентам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            PopupMenuButton<SortOrder>(
              icon: const Icon(Icons.sort),
              onSelected: (order) {
                setState(() {
                  _studentSortOrder = order;
                  _studentAnalytics = _sortAnalytics(_studentAnalytics, _studentSortOrder);
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: SortOrder.descending, child: Text('По убыванию')),
                const PopupMenuItem(value: SortOrder.ascending, child: Text('По возрастанию')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_studentAnalytics.isEmpty)
          const Center(child: Text('Нет данных по студентам'))
        else
          ..._studentAnalytics.map((data) {
            final percent = double.parse(data['percent']);
            final color = _getPercentColor(percent);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(data['fullName']),
                subtitle: LinearProgressIndicator(
                  value: percent / 100,
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 6,
                ),
                trailing: Text('${data['percent']}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label: $value%'),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 20, color: Colors.white),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: List.generate(2, (index) {
                return Container(height: 100, color: Colors.white);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Не удалось загрузить данные', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}