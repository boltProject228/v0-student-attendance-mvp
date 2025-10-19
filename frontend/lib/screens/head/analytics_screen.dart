import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/screens/head/analytic_attendance_screen.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/analytic_group_card.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/group.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';

class AcademicRange {
  final String label;
  final DateTime startDate;
  final DateTime? endDate;

  AcademicRange({required this.label, required this.startDate, this.endDate});
}

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
  String _selectedGroupChip = '';
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

  // Конфигурируемые даты семестров
  static const int semester1StartMonth = 9;
  static const int semester1StartDay = 2;
  static const int semester1EndMonth = 1;
  static const int semester1EndDay = 15;

  static const int semester2StartMonth = 2;
  static const int semester2StartDay = 1;
  static const int semester2EndMonth = 6;
  static const int semester2EndDay = 30;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
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
      final studentAnalytics = await _calculateStudentAnalytics(attendanceProvider, groupsProvider);

      if (mounted) {
        setState(() {
          _analyticsData = overallAnalytics;
          _groupAnalytics = groupAnalytics;
          _studentAnalytics = _sortAnalytics(studentAnalytics, _studentSortOrder);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      final aVal = double.tryParse(a['percent'].toString()) ?? 0.0;
      final bVal = double.tryParse(b['percent'].toString()) ?? 0.0;
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
        present += (stats['present'] ?? 0) + (stats['ithub'] ?? 0);
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

    final numDays = dates.length;

    List<Map<String, dynamic>> groupData = [];
    for (var group in groupsProvider.groups) {
      double present = 0;
      double absent = 0;
      double sick = 0;
      double ithub = 0;
      int totalMarked = 0;
      int studentCount = attendanceProvider.getGroupStudentCount(group.id);

      for (var date in dates) {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
        present += stats['present'] ?? 0;
        absent += stats['absent'] ?? 0;
        sick += stats['sick'] ?? 0;
        ithub += stats['ithub'] ?? 0;
        totalMarked += stats['marked'] ?? 0;
      }

      final total = totalMarked > 0 ? totalMarked : 1;
      final attendancePercent = ((present + ithub) / total * 100).toStringAsFixed(1);

      groupData.add({
        'groupId': group.id,
        'name': group.name,
        'specialty': group.specialty,
        'course': group.course,
        'percent': attendancePercent,
        'studentCount': studentCount,
        'presentCount': present.toInt(),
        'absentCount': absent.toInt(),
        'sickCount': sick.toInt(),
        'ithubCount': ithub.toInt(),
        'markedCount': totalMarked,
        'numDays': numDays,
      });
    }

    return groupData;
  }

  Future<List<Map<String, dynamic>>> _calculateStudentAnalytics(
    AttendanceProvider attendanceProvider,
    GroupsProvider groupsProvider,
  ) async {
    final start = _isRange ? _startDate : _startDate;
    final end = _isRange ? _endDate : _startDate;
    final dates = _isRange
        ? _generateDateRange(start!, end!)
        : [DateFormat('yyyy-MM-dd').format(start!)];

    final groupMap = {for (var group in groupsProvider.groups) group.id: group};

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

      final String groupName = groupMap[student.groupId]?.name ?? 'Группа не указана';

      studentData.add({
        'studentId': student.id,
        'fullName': student.fullName,
        'groupId': student.groupId,
        'groupName': groupName,
        'percent': percent,
      });
    }

    return studentData;
  }

  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    for (var date = start; date.isBefore(end.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
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
      final matchesGroup = _selectedGroupChip.isEmpty || data['groupId'] == _selectedGroupChip;
      final studentGroup = groups.firstWhere(
        (g) => g.id == data['groupId'],
        orElse: () => Group(id: '', name: '', specialty: '', course: 0, createdAt: DateTime.now()),
      );
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

  List<AcademicRange> _generateFixedRanges() {
    final now = DateTime.now();
    List<AcademicRange> ranges = [];

    ranges.add(AcademicRange(label: 'Сегодня', startDate: now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)));

    int acYearStart = now.month >= semester1StartMonth ? now.year : now.year - 1;
    int acYearEnd = acYearStart + 1;

    DateTime iStart = DateTime(acYearStart, semester1StartMonth, semester1StartDay);
    DateTime iEnd = DateTime(acYearEnd, semester1EndMonth, semester1EndDay);
    String iLabel = 'I семестр ($acYearStart/$acYearEnd)';
    ranges.add(AcademicRange(label: iLabel, startDate: iStart, endDate: iEnd));

    DateTime month = DateTime(acYearStart, 9, 1);
    while (month.isBefore(iEnd.add(const Duration(days: 1)))) {
      DateTime startOfMonth = month;
      DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0);
      DateTime finalEndDate = endOfMonth.isAfter(iEnd) ? iEnd : endOfMonth;
      String monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(startOfMonth);
      ranges.add(AcademicRange(label: monthLabel, startDate: startOfMonth, endDate: finalEndDate));
      month = _addMonth(month);
      if (month.isAfter(iEnd)) break;
    }

    DateTime iiStart = DateTime(acYearEnd, semester2StartMonth, semester2StartDay);
    DateTime iiEnd = DateTime(acYearEnd, semester2EndMonth, semester2EndDay);
    String iiLabel = 'II семестр ($acYearStart/$acYearEnd)';
    ranges.add(AcademicRange(label: iiLabel, startDate: iiStart, endDate: iiEnd));

    DateTime monthII = DateTime(acYearEnd, semester2StartMonth, 1);
    while (monthII.isBefore(iiEnd.add(const Duration(days: 1)))) {
      DateTime startOfMonth = monthII;
      DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0);
      DateTime finalEndDate = endOfMonth.isAfter(iiEnd) ? iiEnd : endOfMonth;
      String monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(startOfMonth);
      ranges.add(AcademicRange(label: monthLabel, startDate: startOfMonth, endDate: finalEndDate));
      monthII = _addMonth(monthII);
      if (monthII.isAfter(iiEnd)) break;
    }

    return ranges;
  }

  DateTime _addMonth(DateTime date) {
    int nextMonth = date.month + 1;
    int nextYear = date.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    return DateTime(nextYear, nextMonth, 1);
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
      _startDate = newStartDate;
      _endDate = newEndDate;
      _isRange = newIsRange;
    });

    await _loadAnalytics();
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T element) test) {
    for (var element in items) {
      if (test(element)) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final filteredGroups = _filteredGroups(_groupAnalytics, groupsProvider.groups, attendanceProvider.students);
    final filteredStudents = _filteredStudents(_studentAnalytics, attendanceProvider.students, groupsProvider.groups);

    final dateStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';

    Widget? drawerWidget;
    if (authProvider.isHead) {
      drawerWidget = const HeadHomeDrawer();
    } else if (authProvider.isAdmin) {
      drawerWidget = const AdminHomeDrawer();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final double titleFontSize = isMobile ? 17.0 : 20.0;
    final double tabFontSize = isMobile ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
      title: Text(
        'Аналитика посещаемости',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: titleFontSize, // 👈 Адаптивный размер шрифта
        ),
      ),
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
                      _buildDateFilter(isMobile),
                      SizedBox(height: isMobile ? 12 : 24),
                      TabBar(
                        controller: _tabController,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: tabFontSize),
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
                              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                              children: [
                                _buildGroupFilters(isMobile),
                                SizedBox(height: isMobile ? 8 : 16),
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
                                      padding: EdgeInsets.only(bottom: isMobile ? 10 : 20),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 280, // Adjusted to prevent overflow
                                      ),
                                      itemCount: filteredGroups.length,
                                      itemBuilder: (context, index) {
                                        final group = filteredGroups[index];
                                        final studentCount = attendanceProvider.getGroupStudentCount(group.id);
                                        final bool isRangeSelected = _isRange;
                                        final Map<String, int> dataForCard = {};
                                        double rangePercent = 0.0;

                                        if (isRangeSelected) {
                                          final groupAnalyticData = _groupAnalytics.firstWhere(
                                            (data) => data['groupId'] == group.id,
                                            orElse: () => {
                                              'percent': '0.0',
                                              'markedCount': 0,
                                              'presentCount': 0,
                                              'absentCount': 0,
                                              'sickCount': 0,
                                              'ithubCount': 0,
                                            },
                                          );
                                          rangePercent = double.tryParse(groupAnalyticData['percent']?.toString() ?? '0.0') ?? 0.0;
                                          dataForCard['markedCount'] = groupAnalyticData['markedCount'] as int? ?? 0;
                                          dataForCard['presentCount'] = groupAnalyticData['presentCount'] as int? ?? 0;
                                          dataForCard['absentCount'] = groupAnalyticData['absentCount'] as int? ?? 0;
                                          dataForCard['sickCount'] = groupAnalyticData['sickCount'] as int? ?? 0;
                                          dataForCard['ithubCount'] = groupAnalyticData['ithubCount'] as int? ?? 0;
                                        } else {
                                          final stats = attendanceProvider.getGroupAttendanceStats(group.id, dateStr);
                                          final int present = stats['present'] as int? ?? 0;
                                          final int absent = stats['absent'] as int? ?? 0;
                                          final int sick = stats['sick'] as int? ?? 0;
                                          final int ithub = stats['ithub'] as int? ?? 0;
                                          final int marked = stats['marked'] as int? ?? 0;
                                          final double totalMarkedDouble = (marked > 0) ? marked.toDouble() : 1.0;
                                          final int presentTotal = present + ithub;
                                          rangePercent = (presentTotal / totalMarkedDouble * 100);
                                          dataForCard['presentCount'] = present;
                                          dataForCard['absentCount'] = absent;
                                          dataForCard['sickCount'] = sick;
                                          dataForCard['ithubCount'] = ithub;
                                          dataForCard['markedCount'] = marked;
                                        }

                                        return AnalyticGroupCard(
                                          group: group,
                                          studentCount: studentCount,
                                          markedCount: dataForCard['markedCount']!,
                                          presentCount: dataForCard['presentCount']!,
                                          absentCount: dataForCard['absentCount']!,
                                          sickCount: dataForCard['sickCount']!,
                                          ithubCount: dataForCard['ithubCount']!,
                                          attendancePercentage: rangePercent,
                                          isRangeSelected: isRangeSelected,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AnalyticAttendanceScreen(group: group),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            ListView(
                              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                              children: [
                                _buildStudentFilters(isMobile),
                                SizedBox(height: isMobile ? 8 : 16),
                                _buildStudentGroupChips(groupsProvider.groups, isMobile),
                                SizedBox(height: isMobile ? 8 : 16),
                                _buildStudentSort(isMobile),
                                SizedBox(height: isMobile ? 8 : 16),
                                ..._buildStudentList(filteredStudents, isMobile, groupsProvider),
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

  Widget _buildDateFilter(bool isMobile) {
    final List<AcademicRange> fixedRanges = _generateFixedRanges();
    String dateLabel;
    if (_isRange) {
      dateLabel =
          '${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Выбрать'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выбрать'}';
    } else {
      dateLabel = _startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Выбрать дату';
    }

    String? currentPresetLabel;
    if (_startDate != null) {
      final found = _firstWhereOrNull(
        fixedRanges,
        (r) =>
            r.startDate.year == _startDate!.year &&
            r.startDate.month == _startDate!.month &&
            r.startDate.day == _startDate!.day &&
            ((_isRange &&
                    r.endDate != null &&
                    r.endDate!.year == _endDate!.year &&
                    r.endDate!.month == _endDate!.month &&
                    r.endDate!.day == _endDate!.day) ||
                (!_isRange && r.endDate == null)),
      );
      currentPresetLabel = found?.label;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.calendar_today, size: isMobile ? 16 : 20),
              label: Text(
                currentPresetLabel ?? dateLabel,
                style: TextStyle(fontSize: isMobile ? 14 : 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 12),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  locale: const Locale('ru', 'RU'),
                );
                if (pickedRange != null) {
                  final isSingleDay = pickedRange.start.isAtSameMomentAs(pickedRange.end);
                  _setFilterRange(
                    manualStart: pickedRange.start,
                    manualEnd: isSingleDay ? null : pickedRange.end,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AcademicRange>(
            icon: Icon(Icons.filter_list, size: isMobile ? 20 : 24),
            onSelected: (AcademicRange range) {
              _setFilterRange(fixedRange: range);
            },
            itemBuilder: (BuildContext context) {
              return fixedRanges.map((AcademicRange range) {
                return PopupMenuItem<AcademicRange>(
                  value: range,
                  child: Text(range.label),
                );
              }).toList();
            },
          ),
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
      final bool isRangeSelected = _isRange;
      final Map<String, int> dataForCard = {};
      double rangePercent = 0.0;

      if (isRangeSelected) {
        final groupAnalyticData = _groupAnalytics.firstWhere(
          (data) => data['groupId'] == group.id,
          orElse: () => {
            'percent': '0.0',
            'markedCount': 0,
            'presentCount': 0,
            'absentCount': 0,
            'sickCount': 0,
            'ithubCount': 0,
          },
        );
        rangePercent = double.tryParse(groupAnalyticData['percent']?.toString() ?? '0.0') ?? 0.0;
        dataForCard['markedCount'] = groupAnalyticData['markedCount'] as int? ?? 0;
        dataForCard['presentCount'] = groupAnalyticData['presentCount'] as int? ?? 0;
        dataForCard['absentCount'] = groupAnalyticData['absentCount'] as int? ?? 0;
        dataForCard['sickCount'] = groupAnalyticData['sickCount'] as int? ?? 0;
        dataForCard['ithubCount'] = groupAnalyticData['ithubCount'] as int? ?? 0;
      } else {
        final stats = attendanceProvider.getGroupAttendanceStats(group.id, dateStr);
        final int present = stats['present'] as int? ?? 0;
        final int absent = stats['absent'] as int? ?? 0;
        final int sick = stats['sick'] as int? ?? 0;
        final int ithub = stats['ithub'] as int? ?? 0;
        final int marked = stats['marked'] as int? ?? 0;
        final double totalMarkedDouble = (marked > 0) ? marked.toDouble() : 1.0;
        final int presentTotal = present + ithub;
        rangePercent = (presentTotal / totalMarkedDouble * 100);
        dataForCard['presentCount'] = present;
        dataForCard['absentCount'] = absent;
        dataForCard['sickCount'] = sick;
        dataForCard['ithubCount'] = ithub;
        dataForCard['markedCount'] = marked;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: AnalyticGroupCard(
          group: group,
          studentCount: studentCount,
          markedCount: dataForCard['markedCount']!,
          presentCount: dataForCard['presentCount']!,
          absentCount: dataForCard['absentCount']!,
          sickCount: dataForCard['sickCount']!,
          ithubCount: dataForCard['ithubCount']!,
          attendancePercentage: rangePercent,
          isRangeSelected: isRangeSelected,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyticAttendanceScreen(group: group),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  List<Widget> _buildStudentList(
    List<Map<String, dynamic>> filteredStudents,
    bool isMobile,
    GroupsProvider groupsProvider,
  ) {
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
      final percent = double.tryParse(data['percent'].toString()) ?? 0.0;
      final color = _getPercentColor(percent);
      final String groupName = data['groupName'] ?? 'Группа не указана';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              data['fullName'] ?? 'Неизвестный студент',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Группа: $groupName',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent / 100,
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
            trailing: Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: isMobile ? 16 : 18,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGroupFilters(bool isMobile) {
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

  Widget _buildStudentFilters(bool isMobile) {
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

  Widget _buildStudentGroupChips(List<Group> groups, bool isMobile) {
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

Widget _buildStudentSort(bool isMobile) {
  // Определяем цвета для состояния Ascending (По возрастанию)
  final ascActive = _studentSortOrder == SortOrder.ascending;
  final ascColor = ascActive ? Colors.blue : Colors.grey.shade600;

  // Определяем цвета для состояния Descending (По убыванию)
  final descActive = _studentSortOrder == SortOrder.descending;
  final descColor = descActive ? Colors.blue : Colors.grey.shade600;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Сортировка по % посещаемости',
        style: TextStyle(
          fontSize: isMobile ? 16 : 18, 
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _studentSortOrder == SortOrder.ascending
            ? 'Сейчас выбрано: по возрастанию'
            : 'Сейчас выбрано: по убыванию',
        style: TextStyle(
          fontSize: isMobile ? 12 : 14, 
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          // 1. Кнопка "По возрастанию" (Icons.arrow_upward)
          TextButton.icon(
            icon: Icon(
              Icons.arrow_upward,
              // Используем ascColor для иконки
              color: ascColor, 
              size: isMobile ? 22 : 28, 
            ),
            label: Text(
              'По возрастанию',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16, 
                // Используем ascColor для текста
                color: ascColor, 
              ),
            ),
            onPressed: () {
              setState(() {
                _studentSortOrder = SortOrder.ascending;
                _studentAnalytics = _sortAnalytics(_studentAnalytics, _studentSortOrder); 
              });
            },
          ),
          SizedBox(width: isMobile ? 8 : 12), // Адаптивный отступ
          
          // 2. Кнопка "По убыванию" (Icons.arrow_downward)
          TextButton.icon(
            icon: Icon(
              Icons.arrow_downward,
              // Используем descColor для иконки
              color: descColor,
              size: isMobile ? 22 : 28, 
            ),
            label: Text(
              'По убыванию',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16, 
                // Используем descColor для текста
                color: descColor,
              ),
            ),
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