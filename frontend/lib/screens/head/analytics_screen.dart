import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/screens/head/analytic_attendance_screen.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/head/head_home_drawer.dart';
import '../../models/group.dart';
import '../../widgets/analytic_group_card.dart';

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

  // Конфигурируемые даты семестров
  static const int semester1StartMonth = 9;  // Сентябрь
  static const int semester1StartDay = 2;    // 2 сентября
  static const int semester1EndMonth = 1;    // Январь
  static const int semester1EndDay = 15;     // 15 января (изменить по необходимости)

  static const int semester2StartMonth = 2;  // Февраль
  static const int semester2StartDay = 1;    // 1 февраля
  static const int semester2EndMonth = 6;    // Июнь
  static const int semester2EndDay = 30;     // 30 июня (изменить по необходимости)

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

// ... внутри class _AnalyticsScreenState extends State<AnalyticsScreen> ...

List<AcademicRange> _generateFixedRanges() {
    final now = DateTime.now();
    List<AcademicRange> ranges = [];

    // 1. Сегодня
    ranges.add(AcademicRange(label: 'Сегодня', startDate: now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)));

    // Определяем текущий академический год
    int acYearStart = now.month >= semester1StartMonth ? now.year : now.year - 1;
    int acYearEnd = acYearStart + 1;

    // --- I СЕМЕСТР (STATIC) ---
    DateTime iStart = DateTime(acYearStart, semester1StartMonth, semester1StartDay);
    DateTime iEnd = DateTime(acYearEnd, semester1EndMonth, semester1EndDay);
    String iLabel = 'I семестр ($acYearStart/$acYearEnd)';
    
    // Добавляем заголовок I Семестра
    ranges.add(AcademicRange(label: iLabel, startDate: iStart, endDate: iEnd));

    // Месяцы I Семестра (Сентябрь – Январь)
    DateTime month = DateTime(acYearStart, 9, 1);
    
    while (month.isBefore(iEnd.add(const Duration(days: 1)))) {
        DateTime startOfMonth = month;
        DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0); 
        
        DateTime finalEndDate = endOfMonth.isAfter(iEnd) ? iEnd : endOfMonth;

        // ИСПРАВЛЕНИЕ: Используем 'LLLL' для Именительного падежа,
        // и не используем replaceFirstMapped, потому что 'LLLL' уже делает первую букву заглавной.
        String monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(startOfMonth);
        
        ranges.add(AcademicRange(label: monthLabel, startDate: startOfMonth, endDate: finalEndDate));
        
        month = _addMonth(month);
        
        if (month.isAfter(iEnd)) break;
    }

    // --- II СЕМЕСТР (STATIC) ---
    DateTime iiStart = DateTime(acYearEnd, semester2StartMonth, semester2StartDay);
    DateTime iiEnd = DateTime(acYearEnd, semester2EndMonth, semester2EndDay);
    String iiLabel = 'II семестр ($acYearStart/$acYearEnd)';

    // Добавляем заголовок II Семестра
    ranges.add(AcademicRange(label: iiLabel, startDate: iiStart, endDate: iiEnd));

    // Месяцы II Семестра (Февраль – Июнь)
    DateTime monthII = DateTime(acYearEnd, semester2StartMonth, 1);
    
    while (monthII.isBefore(iiEnd.add(const Duration(days: 1)))) {
        DateTime startOfMonth = monthII;
        DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0); 
        
        DateTime finalEndDate = endOfMonth.isAfter(iiEnd) ? iiEnd : endOfMonth;

        // ИСПРАВЛЕНИЕ: Используем 'LLLL'
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

  // Единый метод для установки диапазона (заменяет старую логику)
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
      // Если endDate есть, это диапазон
      newIsRange = fixedRange.endDate != null;
    } else if (manualStart != null) {
      // Ручной выбор
      newStartDate = manualStart;
      newEndDate = manualEnd;
      // Если есть конечная дата, это диапазон
      newIsRange = manualEnd != null;
    } else {
      // По умолчанию - Сегодня
      newStartDate = DateTime.now();
      newEndDate = null;
      newIsRange = false;
    }

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
      _isRange = newIsRange;
    });

    // Всегда вызываем загрузку данных после изменения диапазона
    _loadAnalytics();


  }

      // Метод-хелпер для поиска первого элемента или возврата null (заменяет функциональность .firstWhereOrNull)
T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T element) test) {
  for (var element in items) {
    if (test(element)) return element;
  }
  return null;
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
                      _buildDateFilter(isMobile),
                      SizedBox(height: isMobile ? 12 : 24),
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
                                        crossAxisSpacing: isMobile ? 8 : 16,
                                        mainAxisSpacing: isMobile ? 16 : 32,
                                        mainAxisExtent: isMobile ? 270 : 290,
                                      ),
                                      itemCount: filteredGroups.length,
                                      itemBuilder: (context, index) {
                                        final group = filteredGroups[index];
final studentCount = attendanceProvider.getGroupStudentCount(group.id);
final stats = attendanceProvider.getGroupAttendanceStats(group.id, dateStr);

// 🔍 Находим запись с рассчитанным процентом за ВЕСЬ диапазон
final groupAnalyticData = _groupAnalytics.firstWhere(
    (data) => data['groupId'] == group.id,
    orElse: () => {'percent': '0.0'},
);
final double rangePercent = double.tryParse(groupAnalyticData['percent'] ?? '0.0') ?? 0.0;

return AnalyticGroupCard(
  group: group,
  studentCount: studentCount,
  markedCount: stats['marked'] ?? 0,
  presentCount: stats['present'] ?? 0,
  absentCount: stats['absent'] ?? 0,
  sickCount: stats['sick'] ?? 0,
  ithubCount: stats['ithub'] ?? 0,
  // 🚀 Используем рассчитанный процент за ВЕСЬ диапазон
  attendancePercentage: rangePercent, 
  onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticAttendanceScreen(group: group)));
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
                                ..._buildStudentList(filteredStudents, isMobile),
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

    // Форматируем текущий выбранный диапазон для отображения
    String dateLabel;
    if (_isRange) {
        dateLabel = '${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Выбрать'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выбрать'}';
    } else {
        dateLabel = _startDate != null
            ? DateFormat('dd.MM.yyyy').format(_startDate!)
            : 'Выбрать дату';
    }

    // Ищем, соответствует ли текущий диапазон одному из фиксированных для отображения его метки
    String? currentPresetLabel;
    if (_startDate != null) {
        // Вызов хелпера для поиска совпадения
        final found = _firstWhereOrNull( 
            fixedRanges,
            (r) => r.startDate.year == _startDate!.year && 
                   r.startDate.month == _startDate!.month && 
                   r.startDate.day == _startDate!.day &&
                   // Если это диапазон
                   ((_isRange && r.endDate != null && r.endDate!.year == _endDate!.year && r.endDate!.month == _endDate!.month && r.endDate!.day == _endDate!.day) || 
                   // Если это одиночный день
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
                            currentPresetLabel ?? dateLabel, // Показать метку пресета или формат dd.MM.yyyy
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 12),
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                        ),
                        // Ручной выбор: вызываем Range Picker для диапазона
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
                // Выбор фиксированных пресетов
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

  List<Widget> _buildStudentList(List<Map<String, dynamic>> filteredStudents, bool isMobile) {
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