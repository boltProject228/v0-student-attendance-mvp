import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/screens/head/analytic_attendance_screen.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/head/head_home_drawer.dart';
import '../../models/group.dart';
import '../../widgets/analytic_group_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum SortOrder { ascending, descending }

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _groupAnalytics = [];
  List<Map<String, dynamic>> _studentAnalytics = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = false;

  // Для групп
  String _groupSearchQuery = '';
  String _groupSelectedSpecialty = 'Все';
  String _groupSelectedCourse = 'Все';

  // Для студентов
  String _studentSearchQuery = '';
  String _studentSelectedSpecialty = 'Все';
  String _studentSelectedCourse = 'Все';
  String _selectedGroupChip = ''; // Для фильтра по чипу группы
  SortOrder _studentSortOrder = SortOrder.descending;

  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      return order == SortOrder.ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
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
        present += stats['present'] ?? 0;
        absent += stats['absent'] ?? 0;
        sick += stats['sick'] ?? 0;
        ithub += stats['ithub'] ?? 0;
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
      'countPresent': present.toInt(),
      'countAbsent': absent.toInt(),
      'countSick': sick.toInt(),
      'countIThub': ithub.toInt(),
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
        present += stats['present'] ?? 0;
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
        'groupId': student.groupId,
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
    final normalizedQuery = normalize(_groupSearchQuery);
    final filteredAnalytics = analytics.where((data) {
      final groupName = normalize(data['name']);
      final specialty = normalize(data['specialty']);
      final courseStr = data['course'].toString();

      final matchesSearch = groupName.contains(normalizedQuery) ||
          students.any((s) => s.groupId == data['groupId'] && normalize(s.fullName).contains(normalizedQuery));
      final matchesCourse = _groupSelectedCourse == 'Все' || courseStr == _groupSelectedCourse;
      final matchesSpecialty = _groupSelectedSpecialty == 'Все' || specialty.contains(normalize(_groupSelectedSpecialty));

      return matchesSearch && matchesCourse && matchesSpecialty;
    }).map((data) => data['groupId']).toSet();

    return allGroups.where((group) => filteredAnalytics.contains(group.id)).toList();
  }

  List<Map<String, dynamic>> _filteredStudents(
    List<Map<String, dynamic>> analytics,
    List<Student> students,
    List<Group> groups,
  ) {
    final normalizedQuery = normalize(_studentSearchQuery);
    return analytics.where((data) {
      final fullName = normalize(data['fullName']);
      final matchesSearch = fullName.contains(normalizedQuery);

      // Фильтр по группе (чип)
      final matchesGroup = _selectedGroupChip.isEmpty || data['groupId'] == _selectedGroupChip;

      // Фильтр по specialty и course через группу студента
      final studentGroup = groups.firstWhere((g) => g.id == data['groupId'], orElse: () => Group(id: '', name: '', specialty: '', course: 0, createdAt: DateTime.now()));
      final specialty = normalize(studentGroup.specialty);
      final courseStr = studentGroup.course.toString();

      final matchesCourse = _studentSelectedCourse == 'Все' || courseStr == _studentSelectedCourse;
      final matchesSpecialty = _studentSelectedSpecialty == 'Все' || specialty.contains(normalize(_studentSelectedSpecialty));

      return matchesSearch && matchesGroup && matchesCourse && matchesSpecialty;
    }).toList();
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
    final authProvider = Provider.of<AuthProvider>(context);

    final filteredGroups = _filteredGroups(_groupAnalytics, groupsProvider.groups, attendanceProvider.students);
    final filteredStudents = _filteredStudents(_studentAnalytics, attendanceProvider.students, groupsProvider.groups);

    final dateStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';

    Widget? drawerWidget;
    if (authProvider.isHead) {
      drawerWidget = const HeadHomeDrawer();
    } else if (authProvider.isAdmin) {
      drawerWidget = const AdminHomeDrawer();
    }

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
      drawer: drawerWidget,
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _isLoading
            ? _buildSkeletonLoader()
            : _analyticsData == null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildDateFilter(),
                      const SizedBox(height: 24),
                      ExpansionTile(
                        leading: const Icon(Icons.pie_chart),
                        title: const Text('Средняя посещаемость', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        initiallyExpanded: false,
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
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
                      const SizedBox(height: 24),
                      TabBar(
                        controller: _tabController,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Аналитика по группам'),
                          Tab(text: 'Аналитика по студентам'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: [
                                _buildGroupFilters(),
                                const SizedBox(height: 16),
                                LayoutBuilder(
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
                                          attendancePercentage: (stats['marked'] ?? 0) > 0 ? (((stats['present'] ?? 0) + (stats['ithub'] ?? 0)) / (stats['marked'] ?? 1) * 100) : 0.0,
                                          onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticAttendanceScreen(group: group)));} 
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: [
                                _buildStudentFilters(),
                                const SizedBox(height: 16),
                                _buildStudentGroupChips(groupsProvider.groups),
                                const SizedBox(height: 16),
                                _buildStudentSort(),
                                const SizedBox(height: 16),
                                ..._buildStudentList(filteredStudents),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
      ),
    );
  }

  List<Widget> _buildGroupList(
    List<Group> filteredGroups,
    AttendanceProvider attendanceProvider,
    String dateStr,
  ) {
    if (filteredGroups.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Группы не найдены',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        )
      ];
    }

    return filteredGroups.map((group) {
      final studentCount = attendanceProvider.getGroupStudentCount(group.id);
      final stats = attendanceProvider.getGroupAttendanceStats(group.id, dateStr);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: AnalyticGroupCard(
          group: group,
          studentCount: studentCount,
          markedCount: stats['marked'] ?? 0,
          presentCount: stats['present'] ?? 0,
          absentCount: stats['absent'] ?? 0,
          sickCount: stats['sick'] ?? 0,
          ithubCount: stats['ithub'] ?? 0,
          attendancePercentage: (stats['marked'] ?? 0) > 0 ? (((stats['present'] ?? 0) + (stats['ithub'] ?? 0)) / (stats['marked'] ?? 1) * 100) : 0.0,
          onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticAttendanceScreen(group: group)));} 
        ),
      );
    }).toList();
  }

  Widget _buildGroupFilters() {
    return GroupFilters(
      searchQuery: _groupSearchQuery,
      selectedSpecialty: _groupSelectedSpecialty,
      selectedCourse: _groupSelectedCourse,
      specialties: _specialties,
      availableCourses: _courses,
      onSearchChanged: (value) => setState(() => _groupSearchQuery = value),
      onSpecialtyChanged: (value) => setState(() => _groupSelectedSpecialty = value),
      onCourseChanged: (value) => setState(() => _groupSelectedCourse = value),
    );
  }

  Widget _buildStudentFilters() {
    return StudentFilters(
      searchQuery: _studentSearchQuery,
      selectedSpecialty: _studentSelectedSpecialty,
      selectedCourse: _studentSelectedCourse,
      specialties: _specialties,
      availableCourses: _courses,
      onSearchChanged: (value) => setState(() => _studentSearchQuery = value),
      onSpecialtyChanged: (value) => setState(() => _studentSelectedSpecialty = value),
      onCourseChanged: (value) => setState(() => _studentSelectedCourse = value),
    );
  }

  Widget _buildStudentGroupChips(List<Group> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Все группы',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: groups.map((group) {
                final isSelected = _selectedGroupChip == group.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        group.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    backgroundColor: isSelected ? Colors.blue : Colors.blue.shade100,
                    onPressed: () {
                      setState(() {
                        _selectedGroupChip = isSelected ? '' : group.id;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSort() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Сортировка по % посещаемости', style: TextStyle(fontSize: 14)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_upward, color: _studentSortOrder == SortOrder.ascending ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  _studentSortOrder = SortOrder.ascending;
                  _studentAnalytics = _sortAnalytics(_studentAnalytics, _studentSortOrder);
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward, color: _studentSortOrder == SortOrder.descending ? Colors.blue : Colors.grey),
              onPressed: () {
                setState(() {
                  _studentSortOrder = SortOrder.descending;
                  _studentAnalytics = _sortAnalytics(_studentAnalytics, _studentSortOrder);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStudentList(List<Map<String, dynamic>> filteredStudents) {
    if (filteredStudents.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Студенты не найдены',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        )
      ];
    }

    return filteredStudents.map((data) {
      final percent = double.parse(data['percent']);
      final color = _getPercentColor(percent);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Card(
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
        ),
      );
    }).toList();
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

class StudentFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedSpecialty;
  final String selectedCourse;
  final List<String> specialties;
  final List<String> availableCourses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<String> onCourseChanged;

  const StudentFilters({
    super.key,
    required this.searchQuery,
    required this.selectedSpecialty,
    required this.selectedCourse,
    required this.specialties,
    required this.availableCourses,
    required this.onSearchChanged,
    required this.onSpecialtyChanged,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Имя студента',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Поиск по имени студента',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Специальность',
                  value: selectedSpecialty,
                  items: specialties,
                  onChanged: onSpecialtyChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Курс',
                  value: selectedCourse,
                  items: availableCourses,
                  onChanged: onCourseChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
          items: items.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: Colors.black)))).toList(),
          onChanged: (val) => onChanged(val ?? value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class GroupFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedSpecialty;
  final String selectedCourse;
  final List<String> specialties;
  final List<String> availableCourses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<String> onCourseChanged;

  const GroupFilters({
    super.key,
    required this.searchQuery,
    required this.selectedSpecialty,
    required this.selectedCourse,
    required this.specialties,
    required this.availableCourses,
    required this.onSearchChanged,
    required this.onSpecialtyChanged,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Название группы',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Поиск по названию группы',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Специальность',
                  value: selectedSpecialty,
                  items: specialties,
                  onChanged: onSpecialtyChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Курс',
                  value: selectedCourse,
                  items: availableCourses,
                  onChanged: onCourseChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
          items: items.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: Colors.black)))).toList(),
          onChanged: (val) => onChanged(val ?? value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}