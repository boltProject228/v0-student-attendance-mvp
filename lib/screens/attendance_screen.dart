import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_tile.dart';
import '../widgets/summary_bar.dart';

class AttendanceScreen extends StatefulWidget {
  final Group group;

  const AttendanceScreen({super.key, required this.group});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, String> _statuses = {};
  final Map<String, String> _attIds = {};

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchStudents();
    _loadExistingAttendances();
  }

  Future<void> _loadExistingAttendances() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final attendances = await provider.getAttendances(widget.group.id, today);
    setState(() {
      for (var entry in attendances.entries) {
        _statuses[entry.key] = entry.value['status']!;
        _attIds[entry.key] = entry.value['id']!;
      }
    });
  }

  Map<String, int> get _summary {
    final stats = {
      'present': 0,
      'absent': 0,
      'sick': 0,
      'wsk': 0,
      'unmarked': 0,
    };

    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final students = provider.students
        .where((s) => s.groupId == widget.group.id)
        .toList();

    for (final student in students) {
      final s = _statuses[student.id] ?? 'unmarked';
      if (s == 'unmarked' || s.isEmpty) {
        stats['unmarked'] = (stats['unmarked'] ?? 0) + 1;
      } else {
        stats[s] = (stats[s] ?? 0) + 1;
      }
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);

    // Получаем список студентов этой группы
    final students = provider.students
        .where((s) => s.groupId == widget.group.id)
        .toList();

    // Считаем общее количество студентов
    final studentCount = students.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Группа ${widget.group.name}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  'Всего в группе: $studentCount', // ✅ теперь работает
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final status = _statuses[student.id] ?? 'unmarked';
            return AttendanceTile(
              name: student.fullName,
              status: status,
              onStatusChange: (newStatus) {
                setState(() => _statuses[student.id] = newStatus);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SummaryBar(
        present: _summary['present'] ?? 0,
        absent: _summary['absent'] ?? 0,
        sick: _summary['sick'] ?? 0,
        wsk: _summary['wsk'] ?? 0,
        unmarked: _summary['unmarked'] ?? 0,
        onSave: _saveAttendance,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final nowIso = DateTime.now().toIso8601String();

    for (var entry in _statuses.entries) {
      String studentId = entry.key;
      String status = entry.value;
      var data = {
        'studentId': studentId,
        'groupId': widget.group.id,
        'date': nowIso,
        'updatedBy': '1', // Mock user
      };
      String? attId = _attIds[studentId];

      if (status == 'unmarked') {
        if (attId != null) {
          data['status'] = '';
          await provider.updateAttendance(attId, data);
        }
      } else {
        data['status'] = status;
        if (attId != null) {
          await provider.updateAttendance(attId, data);
        } else {
          String? newId = await provider.createAttendance(data);
          if (newId != null) {
            setState(() {
              _attIds[studentId] = newId;
            });
          }
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Посещаемость сохранена ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
