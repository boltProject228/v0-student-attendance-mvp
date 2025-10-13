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

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchStudents();
    _loadExistingAttendances();  // Добавлено для загрузки существующих данных из провайдера
  }

  Future<void> _loadExistingAttendances() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final today = DateTime.now().toIso8601String().split('T')[0];  // Или используйте подходящий формат даты для вашего бэкенда
    final attendances = await provider.getAttendances(widget.group.id, today);
    setState(() {
      for (var entry in attendances.entries) {
        _statuses[entry.key] = entry.value.isEmpty ? 'unmarked' : entry.value;
      }
    });
  }

  Map<String, int> get _summary {
    final stats = {
      'present': 0,
      'absent': 0,
      'sick': 0,
      'wsk': 0,
      'unmarked': 0
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
    final students = provider.students
        .where((s) => s.groupId == widget.group.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Группа ${widget.group.name}',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final status = _statuses[student.id] ?? 'unmarked'; // 👈 если пусто — "Не отмечен"
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
    for (var entry in _statuses.entries) {
      await provider.createAttendance({
        'studentId': entry.key,
        'groupId': widget.group.id,
        'status': entry.value == 'unmarked' ? '' : entry.value,
        'date': DateTime.now().toIso8601String(),
      });
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