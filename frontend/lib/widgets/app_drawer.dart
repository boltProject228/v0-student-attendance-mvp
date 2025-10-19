import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.login ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.role == 'head' ? 'Завкафедры' : 'Преподаватель',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Главная'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Посещаемость'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/attendance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Группы'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/groups');
            },
          ),
          if (user?.isHead == true)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Администрирование'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
            ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Аналитика'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/analytics');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выйти'),
            onTap: () async {
              await authProvider.logout(context);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}