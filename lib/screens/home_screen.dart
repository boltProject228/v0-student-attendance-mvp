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
import 'attendance_screen.dart'; // 🟡 добавляем импорт

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

  List<Group> _filteredGroups(List<Group> groups, List<Student> students) {
    return groups.where((group) {
      final lowerQuery = _searchQuery.toLowerCase();
      final matchesSearch = group.name.toLowerCase().contains(lowerQuery) ||
          students.any((s) => s.groupId == group.id && s.fullName.toLowerCase().contains(lowerQuery));
      final matchesCourse = _selectedCourse == 'Все' || group.course.toString() == _selectedCourse;
      final matchesSpecialty = _selectedSpecialty == 'Все' || group.specialty == _selectedSpecialty;
      return matchesSearch && matchesCourse && matchesSpecialty;
    }).toList();
  }

  int _getStudentCount(String groupId, List<Student> students) {
    return students.where((s) => s.groupId == groupId).length;
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
    if (_selectedSpecialty == 'ТЭ(Ру)' || _selectedSpecialty == 'ТЭ(Қаз)') {
      availableCourses = ['Все', '1', '2', '3', '4'];
    }

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
                        } else {
                          crossAxisCount = 1;
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
final stats = attendanceProvider.getGroupAttendanceStats(group.id);


                            return GroupCard(
                              group: group,
                              studentCount: studentCount,
                              markedCount: 0,
                              presentCount: 0,
                              absentCount: 0,
                              sickCount: 0,
                              wskCount: 0,
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
