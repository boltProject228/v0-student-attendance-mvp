// main.dart (No changes needed beyond what's provided, but ensure Hive init is correct)
import 'package:attendance_system/providers/admin_provider.dart';
import 'package:attendance_system/screens/head/export_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/attendance.dart';
import 'models/group.dart';
import 'models/student.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/groups_provider.dart';
import 'screens/login_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/head/head_home_screen.dart';
import 'screens/head/analytics_screen.dart';
import 'screens/attendance_screen.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AttendanceAdapter());
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(UserAdapter());
  await HiveService.init();
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
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Attendance System',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
                bodySmall: TextStyle(color: Colors.black87),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
                labelStyle: const TextStyle(color: Colors.black),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.black),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            initialRoute: '/',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/teacher_home': (context) => const TeacherHomeScreen(),
              '/head_home': (context) => const HeadHomeScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/attendance': (context) {
                final group = ModalRoute.of(context)!.settings.arguments as Group;
                return AttendanceScreen(group: group);
              
              },
              '/export': (context) => const ExportScreen()
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                final user = authProvider.user;
                if (user != null) {
                  if (user.role == 'teacher') {
                    return MaterialPageRoute(builder: (context) => const TeacherHomeScreen());
                  } else if (user.role == 'head' || user.role == 'admin') {
                    return MaterialPageRoute(builder: (context) => const HeadHomeScreen());
                  }
                }
                return MaterialPageRoute(builder: (context) => const LoginScreen());
              }
              return null;
            },
          );
        },
      ),
    );
  }
}