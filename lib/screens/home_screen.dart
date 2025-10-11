import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/attendance_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.checkAuth().then((isAuth) {
      if (!isAuth) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Load data
        Provider.of<GroupsProvider>(context, listen: false).fetchGroups();
        Provider.of<GroupsProvider>(context, listen: false).fetchSubjects();
        Provider.of<AttendanceProvider>(context, listen: false).fetchStudents();
        Provider.of<AttendanceProvider>(context, listen: false).fetchAttendance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    if (authProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Добро пожаловать, ${authProvider.user!.login}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Роль: ${authProvider.user!.role}'),
            Text('Настройки: ${authProvider.user!.settings.toString()}'),
            const SizedBox(height: 20),
            const Text('Группы:'),
            ...groupsProvider.groups.map((g) => Text('- ${g.name} (${g.specialty})')),
            const SizedBox(height: 20),
            const Text('Студенты:'),
            ...attendanceProvider.students.map((s) => Text('- ${s.fullName} (Group: ${s.groupId})')),
          ],
        ),
      ),
    );
  }
}