import 'package:attendance_system/models/group.dart';
import 'package:flutter/material.dart';

class StudentList extends StatelessWidget {
  final List<Map<String, dynamic>> filteredStudents;
  final bool isMobile;
  final List<Group> groups;

  const StudentList({
    super.key,
    required this.filteredStudents,
    required this.isMobile,
    required this.groups,
  });

  Color _getPercentColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (filteredStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Студенты не найдены',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: filteredStudents.map((data) {
        final percent = double.tryParse(data['percent'].toString()) ?? 0.0;
        final color = _getPercentColor(percent);
        final String groupName = data['groupName'] ?? 'Группа не указана';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                data['fullName'] ?? 'Неизвестный студент',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Группа: $groupName',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent / 100,
                    color: color,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
              trailing: Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}