import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/group.dart';
import '../../models/student.dart';
import '../../widgets/teacher/teacher_home_appbar.dart';
import '../../widgets/teacher/teacher_home_drawer.dart';
import '../../widgets/home_filters.dart';
import '../../widgets/group_card.dart';
import '../../data/mock_data.dart';
import '../attendance_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
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
    final Map<String, String> map = {
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

      return matchesSearch && matchesCourse && matchesSpecialty;
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
    final mockGroups = MockData.mockGetGroups();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: buildTeacherHomeAppBar(context, authProvider),
      drawer: const TeacherHomeDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            HomeFilters(
              searchQuery: _searchQuery,
              selectedSpecialty: _selectedSpecialty,
              selectedCourse: _selectedCourse,
              specialties: _specialties,
              availableCourses: const ['Все', '1', '2', '3', '4'],
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              onSpecialtyChanged: (value) => setState(() {
                _selectedSpecialty = value;
                _selectedCourse = 'Все';
              }),
              onCourseChanged: (value) => setState(() => _selectedCourse = value),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Все группы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
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
            const SizedBox(height: 16),
            Expanded(
              child: filteredGroups.isEmpty
                  ? const Center(child: Text('Группы не найдены'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = 1;
                        double aspectRatio = 1.8;

                        if (width > 1200) {
                          crossAxisCount = 3;
                          aspectRatio = 2.2;
                        } else if (width > 800) {
                          crossAxisCount = 2;
                          aspectRatio = 2.0;
                        } else if (width < 500) {
                          // 📱 Мобильные устройства
                          crossAxisCount = 1;
                          aspectRatio = 1.6;
                        }

                        return GridView.builder(
  padding: const EdgeInsets.only(bottom: 20),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: 16,
    mainAxisSpacing:32,
    mainAxisExtent: 260, // 📏 фиксированная высота карточки
  ),
  itemCount: filteredGroups.length,
  itemBuilder: (context, index) {
    final group = filteredGroups[index];
    final studentCount = attendanceProvider.getGroupStudentCount(group.id);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final stats = attendanceProvider.getGroupAttendanceStats(group.id, today);

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
            ),
          ],
        ),
      ),
    );
  }
}
