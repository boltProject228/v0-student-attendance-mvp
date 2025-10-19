import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/user.dart';
import 'models/group.dart';
import 'models/student.dart';
import 'models/attendance.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/analytics_provider.dart';
import 'screens/login_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/head/head_home_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/head/analytics_screen.dart';
import 'screens/head/export_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/average_attendance_screen.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(AttendanceAdapter());
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
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Attendance System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (ctx) => const LoginGuard(child: LoginScreen()),
              );
            case '/access_denied':
              return MaterialPageRoute(
                builder: (ctx) => const AccessDeniedScreen(),
              );
            case '/':
              return MaterialPageRoute(
                builder: (ctx) => FutureBuilder<bool>(
                  future: Provider.of<AuthProvider>(ctx, listen: false).checkAuth(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final auth = Provider.of<AuthProvider>(ctx, listen: false);
                    if (!auth.isAuthenticated) return const LoginScreen();

                    String? home;
                    if (auth.isTeacher) home = '/teacher_home';
                    if (auth.isHead) home = '/head_home';
                    if (auth.isAdmin) home = '/admin';
                    return _buildScreen(home ?? '/login', null);
                  },
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (ctx) => AuthGuard(
                  routeName: settings.name ?? '',
                  arguments: settings.arguments,
                ),
              );
          }
        },
      ),
    );
  }
}

class LoginGuard extends StatelessWidget {
  final Widget child;
  const LoginGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      String home = '/login';
      if (auth.isTeacher) home = '/teacher_home';
      if (auth.isHead) home = '/head_home';
      if (auth.isAdmin) home = '/admin';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 🚀 Исправлено: очищаем стек и обновляем URL
        Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}

class AuthGuard extends StatelessWidget {
  final String routeName;
  final dynamic arguments;
  const AuthGuard({super.key, required this.routeName, this.arguments});

  static const Map<String, List<String>> _rolePermissions = {
    '/teacher_home': ['teacher'],
    '/head_home': ['head'],
    '/admin': ['admin'],
    '/attendance': ['teacher', 'head'],
    '/analytics': ['admin', 'head'],
    '/export': ['admin', 'head'],
    '/average_attendance': ['admin', 'head'],
  };

  List<String> _getAllowedRoles(String route) => _rolePermissions[route] ?? [];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const SizedBox.shrink();
    }

    final allowedRoles = _getAllowedRoles(routeName);
    if (!allowedRoles.contains(auth.user?.role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/access_denied', (route) => false);
      });
      return const SizedBox.shrink();
    }

    return _buildScreen(routeName, arguments);
  }
}

Widget _buildScreen(String route, dynamic args) {
  switch (route) {
    case '/teacher_home':
      return const TeacherHomeScreen();
    case '/head_home':
      return const HeadHomeScreen();
    case '/admin':
      return const AdminScreen();
    case '/attendance':
      return AttendanceScreen(group: args as Group);
    case '/analytics':
      return const AnalyticsScreen();
    case '/export':
      return const ExportScreen();
    case '/average_attendance':
      return const AverageAttendanceScreen();
    default:
      return const AccessDeniedScreen();
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('У вас нет доступа к этой странице', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(context),
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
