import 'package:attendance_system/models/group.dart';
import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/groups_provider.dart';
import 'package:attendance_system/screens/analytics/logic/analytics_calculations.dart';
import 'package:attendance_system/screens/analytics/logic/date_ranges.dart';
import 'package:attendance_system/screens/analytics/logic/filters_helpers.dart';
import 'package:attendance_system/screens/analytics/logic/sorting.dart';
import 'package:attendance_system/screens/analytics/models/academic_range.dart';
import 'package:attendance_system/screens/analytics/widgets/analytics_tab_bar.dart';
import 'package:attendance_system/screens/analytics/widgets/date_filter_bar.dart';
import 'package:attendance_system/screens/analytics/widgets/group_filters.dart';
import 'package:attendance_system/screens/analytics/widgets/student_filters.dart';
import 'package:attendance_system/screens/analytics/widgets/student_group_chips.dart';
import 'package:attendance_system/screens/analytics/widgets/student_list.dart';
import 'package:attendance_system/screens/analytics/widgets/student_sort.dart';
import 'package:attendance_system/screens/head/analytic_attendance_screen.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/analytic_group_card.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

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

      final overallAnalytics = await calculateOverallAnalytics(
        attendanceProvider,
        groupsProvider,
        _startDate,
        _endDate,
        _isRange,
      );
      final groupAnalytics = await calculateGroupAnalytics(
        attendanceProvider,
        groupsProvider,
        _startDate,
        _endDate,
        _isRange,
      );
      final studentAnalytics = await calculateStudentAnalytics(
        attendanceProvider,
        groupsProvider,
        _startDate,
        _endDate,
        _isRange,
      );

      if (mounted) {
        setState(() {
          _analyticsData = overallAnalytics;
          _groupAnalytics = groupAnalytics;
          _studentAnalytics = sortAnalytics(studentAnalytics, _studentSortOrder);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить данные аналитики: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final filteredGroups = filterGroups(
      _groupAnalytics,
      groupsProvider.groups,
      attendanceProvider.students,
      _groupSearchQuery,
      _groupSelectedSpecialty,
      _groupSelectedCourse,
    );
    final filteredStudents = filterStudents(
      _studentAnalytics,
      attendanceProvider.students,
      groupsProvider.groups,
      _studentSearchQuery,
      _studentSelectedSpecialty,
      _studentSelectedCourse,
      _selectedGroupChip,
    );

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Аналитика посещаемости',
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
                      DateFilterBar(
                        isMobile: isMobile,
                        startDate: _startDate,
                        endDate: _endDate,
                        isRange: _isRange,
                        fixedRanges: generateFixedRanges(),
                        onFixedRangeSelected: (range) => _setFilterRange(fixedRange: range),
                        onManualRangeSelected: (start, end) => _setFilterRange(manualStart: start, manualEnd: end),
                      ),
                      SizedBox(height: isMobile ? 12 : 24),
                      AnalyticsTabBar(
                        tabController: _tabController,
                        isMobile: isMobile,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            ListView(
                              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                              children: [
                                GroupFilters(
                                  searchQuery: _groupSearchQuery,
                                  selectedSpecialty: _groupSelectedSpecialty,
                                  selectedCourse: _groupSelectedCourse,
                                  specialties: _specialties,
                                  availableCourses: _courses,
                                  onSearchChanged: (value) => setState(() => _groupSearchQuery = value),
                                  onSpecialtyChanged: (value) => setState(() => _groupSelectedSpecialty = value),
                                  onCourseChanged: (value) => setState(() => _groupSelectedCourse = value),
                                ),
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
                                        mainAxisExtent: 303,
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
                                          final int present = stats['present'] ?? 0;
                                          final int absent = stats['absent'] ?? 0;
                                          final int sick = stats['sick'] ?? 0;
                                          final int ithub = stats['ithub'] ?? 0;
                                          final int marked = (present + absent + ithub);
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
                                          onTap: () async {
                                            final saved = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AnalyticAttendanceScreen(group: group),
                                              ),
                                            );
                                            if (saved == true) {
                                              await _loadAnalytics();
                                            }
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
                                StudentFilters(
                                  searchQuery: _studentSearchQuery,
                                  selectedSpecialty: _studentSelectedSpecialty,
                                  selectedCourse: _studentSelectedCourse,
                                  specialties: _specialties,
                                  availableCourses: _courses,
                                  onSearchChanged: (value) => setState(() => _studentSearchQuery = value),
                                  onSpecialtyChanged: (value) => setState(() => _studentSelectedSpecialty = value),
                                  onCourseChanged: (value) => setState(() => _studentSelectedCourse = value),
                                ),
                                SizedBox(height: isMobile ? 8 : 16),
                                StudentGroupChips(
                                  groups: groupsProvider.groups,
                                  selectedGroupChip: _selectedGroupChip,
                                  isMobile: isMobile,
                                  onGroupSelected: (value) => setState(() => _selectedGroupChip = value),
                                ),
                                SizedBox(height: isMobile ? 8 : 16),
                                StudentSort(
                                  studentSortOrder: _studentSortOrder,
                                  isMobile: isMobile,
                                  onSortChanged: (order) {
                                    setState(() {
                                      _studentSortOrder = order;
                                      _studentAnalytics = sortAnalytics(_studentAnalytics, _studentSortOrder);
                                    });
                                  },
                                ),
                                SizedBox(height: isMobile ? 8 : 16),
                                StudentList(
                                  filteredStudents: filteredStudents,
                                  isMobile: isMobile,
                                  groups: groupsProvider.groups,
                                ),
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
}