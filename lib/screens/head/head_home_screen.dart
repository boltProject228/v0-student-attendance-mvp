import 'package:attendance_system/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/group.dart';
import '../../models/student.dart';
import '../../widgets/head/head_home_appbar.dart';
import '../../widgets/head/head_home_drawer.dart';
import '../../widgets/home_filters.dart';
import '../../widgets/group_card.dart';
import '../attendance_screen.dart';

class HeadHomeScreen extends StatefulWidget {
  const HeadHomeScreen({super.key});

  @override
  State<HeadHomeScreen> createState() => _HeadHomeScreenState();
}

class _HeadHomeScreenState extends State<HeadHomeScreen> {
  String _searchQuery = '';
  String _selectedSpecialty = 'Все';
  String _selectedCourse = 'Все';
  DateTime _selectedDate = DateTime.now();
  String? _selectedGroupId;

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

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.checkAuth().then((isAuth) {
      if (!isAuth) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Provider.of<GroupsProvider>(context, listen: false).fetchGroups();
        Provider.of<AttendanceProvider>(context, listen: false).fetchStudents();
        Provider.of<AttendanceProvider>(context, listen: false).fetchAttendance();
      }
    });
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

  List<Group> _filteredGroups(List<Group> groups, List<Student> students) {
    final normalizedQuery = normalize(_searchQuery);
    return groups.where((group) {
      final groupName = normalize(group.name);
      final specialty = normalize(group.specialty);

      final matchesSearch = groupName.contains(normalizedQuery) ||
          students.any((s) => s.groupId == group.id && normalize(s.fullName).contains(normalizedQuery));

      final matchesCourse = _selectedCourse == 'Все' || group.course.toString() == _selectedCourse;
      final matchesSpecialty = _selectedSpecialty == 'Все' || specialty.contains(normalize(_selectedSpecialty));
      final matchesChip = _selectedGroupId == null || _selectedGroupId == group.id;

      return matchesSearch && matchesCourse && matchesSpecialty && matchesChip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredGroups = _filteredGroups(groupsProvider.groups, attendanceProvider.students);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final mockGroups = MockData.mockGetGroups();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: buildHeadHomeAppBar(context, authProvider),
      drawer: const HeadHomeDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<GroupsProvider>(context, listen: false).fetchGroups();
            await Provider.of<AttendanceProvider>(context, listen: false).fetchAttendance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeFilters(
                        searchQuery: _searchQuery,
                        selectedSpecialty: _selectedSpecialty,
                        selectedCourse: _selectedCourse,
                        specialties: _specialties,
                        availableCourses: ['Все', '1', '2', '3', '4'],
                        onSearchChanged: (value) => setState(() => _searchQuery = value),
                        onSpecialtyChanged: (value) => setState(() {
                          _selectedSpecialty = value;
                          _selectedCourse = 'Все';
                        }),
                        onCourseChanged: (value) => setState(() => _selectedCourse = value),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: HomeFilters(
                          searchQuery: _searchQuery,
                          selectedSpecialty: _selectedSpecialty,
                          selectedCourse: _selectedCourse,
                          specialties: _specialties,
                          availableCourses: ['Все', '1', '2', '3', '4'],
                          onSearchChanged: (value) => setState(() => _searchQuery = value),
                          onSpecialtyChanged: (value) => setState(() {
                            _selectedSpecialty = value;
                            _selectedCourse = 'Все';
                          }),
                          onCourseChanged: (value) => setState(() => _selectedCourse = value),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Все группы',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // 🧭 Чипы групп
                if (groupsProvider.groups.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: mockGroups.map((group) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.blue.shade100,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceScreen(group: group),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                const Text(
                  'Группы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 📊 Грид карточек (адаптивно)
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

                              return GroupCard(
                                group: group,
                                studentCount: studentCount,
                                markedCount: stats['marked'] ?? 0,
                                presentCount: stats['present'] ?? 0,
                                absentCount: stats['absent'] ?? 0,
                                sickCount: stats['sick'] ?? 0,
                                ithubCount: stats['ithub'] ?? 0,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AttendanceScreen(group: group),
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
          ),
        ),
      ),
    );
  }
}
