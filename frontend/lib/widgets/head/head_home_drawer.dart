// frontend/lib/widgets/head/head_home_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HeadHomeDrawer extends StatelessWidget {
  const HeadHomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1976D2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.supervisor_account, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(
                  user?.login ?? 'head',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Заведующий – ${user?.fullName ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Главная', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/head_home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.white),
            title: const Text('Аналитика', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart, color: Colors.white),
            title: const Text('Средняя посещаемость', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/average_attendance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('Экспорт', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/export');
            },
          ),
          const Divider(color: Colors.white24, thickness: 1),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: const Text('Выйти', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}