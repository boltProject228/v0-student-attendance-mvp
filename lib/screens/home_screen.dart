import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/attendance_provider.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../widgets/home_appbar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/home_filters.dart';
import '../widgets/group_card.dart';
import '../data/mock_data.dart';
import 'attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  /// Функция для нормализации текста: перевод в верхний регистр и замена специфических символов
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

  /// Фильтрация групп с учетом нормализации для поиска
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

    List<String> availableCourses = ['Все', '1', '2', '3', '4'];

    // Верхние чипы из mockGroups
    final mockGroups = MockData.mockGetGroups();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: buildHomeAppBar(context, authProvider),
      drawer: const HomeDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            HomeFilters(
              searchQuery: _searchQuery,
              selectedSpecialty: _selectedSpecialty,
              selectedCourse: _selectedCourse,
              specialties: _specialties,
              availableCourses: availableCourses,
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
              height: 50, // достаточно для ActionChip
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
                        int crossAxisCount = 1;
                        double maxWidth = constraints.maxWidth;

                        if (maxWidth > 1200) {
                          crossAxisCount = 3;
                        } else if (maxWidth > 800) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.8,
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
                              wskCount: stats['wsk'] ?? 0,
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
