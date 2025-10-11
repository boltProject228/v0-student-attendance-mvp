import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // NEW
import 'package:provider/provider.dart';
import 'models/attendance.dart'; // NEW for adapters
import 'models/group.dart';
import 'models/student.dart';
import 'models/subject.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/analytics_screen.dart';
import 'services/api_service.dart'; // Без изменений
import 'services/hive_service.dart'; // NEW: Замена storage_service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NEW: Инициализация Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AttendanceAdapter());
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(UserAdapter());
  await HiveService.init(); // Открываем Box

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Attendance System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/groups': (context) => const GroupsScreen(),
          '/admin': (context) => const AdminScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
        },
      ),
    );
  }
}