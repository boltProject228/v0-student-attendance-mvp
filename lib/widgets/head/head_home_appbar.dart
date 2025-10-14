import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

AppBar buildHeadHomeAppBar(BuildContext context, AuthProvider authProvider) {
  return AppBar(
    iconTheme: const IconThemeData(color: Colors.black, size: 28),
    backgroundColor: Colors.white,
    elevation: 0,
    shape: const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Управление посещаемостью',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          'Заведующий – ${authProvider.user?.fullName ?? authProvider.user?.login ?? 'Абдурахманов Серик'}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}