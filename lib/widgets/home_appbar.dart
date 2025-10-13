import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';

AppBar buildHomeAppBar(BuildContext context, AuthProvider authProvider) {
  return AppBar(
    iconTheme: const IconThemeData(color: Colors.black, size: 28),
    backgroundColor: Colors.white,
    elevation: 0,
    shape: const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Посещаемость студентов',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          'Преподаватель – ${authProvider.user?.fullName ?? authProvider.user?.login ?? 'Базарбай Ерсултан'}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.person, color: Colors.grey.shade600),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    ],
  );
}
