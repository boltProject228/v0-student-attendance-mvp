import 'package:attendance_system/models/attendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
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
  DateTime? _lastUpdatedAt;
  String? _lastUpdatedByName;
  String? _lastUpdatedByRole;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    await provider.fetchStudents();
    await _loadExistingAttendances();
  }

  Future<void> _loadExistingAttendances() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await provider.fetchAttendance(groupId: widget.group.id, date: today, forceRefresh: true);

    final attendances = await provider.getAttendances(widget.group.id, today);

    DateTime? maxUpdatedAt;
    Attendance? lastAttendance;

    for (var att in provider.attendanceList.where((a) =>
        a.groupId == widget.group.id && DateFormat('yyyy-MM-dd').format(a.date) == today)) {
      if (maxUpdatedAt == null || att.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = att.updatedAt;
        lastAttendance = att;
      }
    }

    if (!mounted) return;

    setState(() {
      _statuses.clear();
      _attIds.clear();
      for (var entry in attendances) {
        _statuses[entry['id']!] = entry['status']!;
        _attIds[entry['id']!] = entry['id']!;
      }
      _lastUpdatedByName = lastAttendance?.updatedByName;
      _lastUpdatedByRole = lastAttendance?.updatedByRole;
      _lastUpdatedAt = lastAttendance?.updatedAt.toLocal();
    });
  }

  String _mapRoleToRussian(String? role) {
    if (role == null) return '';
    switch (role.toLowerCase()) {
      case 'head': return 'заведующий';
      case 'teacher': return 'преподаватель';
      case 'admin': return 'администратор';
      default: return role;
    }
  }

  Map<String, int> get _summary {
    final stats = {
      'present': 0,
      'absent': 0,
      'sick': 0,
      'ithub': 0,
      'unmarked': 0,
    };
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final students = provider.students.where((s) => s.groupId == widget.group.id).toList();

    for (final student in students) {
      final status = _statuses[student.id] ?? 'unmarked';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  Future<void> _saveAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final today = DateTime.now();

    if (authProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: пользователь не аутентифицирован'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (today.weekday == DateTime.saturday || today.weekday == DateTime.sunday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нельзя редактировать отметки в выходные дни (суббота и воскресенье).'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final dateUtc = DateTime.utc(today.year, today.month, today.day).toIso8601String();
    bool success = true;

    for (var entry in _statuses.entries) {
      final studentId = entry.key;
      final status = entry.value;
      final attId = _attIds[studentId];

      final data = {
        'studentId': studentId,
        'groupId': widget.group.id,
        'date': dateUtc,
        'status': status,
        'updatedBy': authProvider.user!.id,
      };

      if (status == 'unmarked' || status.isEmpty) {
        if (attId != null) {
          if (!await provider.deleteAttendance(attId)) success = false;
          setState(() {
            _attIds.remove(studentId);
            _statuses[studentId] = 'unmarked';
          });
        }
      } else {
        if (attId != null) {
          if (!await provider.updateAttendance(attId, data)) success = false;
        } else {
          final newId = await provider.createAttendance(data);
          if (newId == null) {
            success = false;
          } else {
            setState(() {
              _attIds[studentId] = newId;
            });
          }
        }
      }
    }

    await _loadExistingAttendances();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Посещаемость сохранена ✅'
              : 'Ошибка сохранения: ${provider.error ?? 'Неизвестная ошибка'}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final students = provider.students.where((s) => s.groupId == widget.group.id).toList();
    final studentCount = students.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final displayRole = _mapRoleToRussian(_lastUpdatedByRole);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: isMobile ? 8 : null,
        title: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Группа ${widget.group.name}',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Всего: $studentCount',
                          style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Группа ${widget.group.name}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        'Всего: $studentCount',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (_lastUpdatedByName != null && _lastUpdatedByRole != null && _lastUpdatedAt != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0, vertical: 6.0),
              child: Text(
                'Обновлено: $_lastUpdatedByName ($displayRole) в ${DateFormat('HH:mm dd.MM.yyyy').format(_lastUpdatedAt!)}',
                style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.grey),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 6.0 : 16.0, vertical: 6.0),
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final status = _statuses[student.id] ?? 'unmarked';
                        final attId = _attIds[student.id] ?? '';
                        return AttendanceTile(
                          index: index + 1,
                          name: student.fullName,
                          status: status,
                          attId: attId,
                          onStatusChange: (newStatus) {
                            setState(() {
                              _statuses[student.id] = newStatus;
                              if (newStatus == 'unmarked') _attIds.remove(student.id);
                            });
                          },
                          isMobile: isMobile,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SummaryBar(
        present: _summary['present'] ?? 0,
        absent: _summary['absent'] ?? 0,
        sick: _summary['sick'] ?? 0,
        ithub: _summary['ithub'] ?? 0,
        unmarked: _summary['unmarked'] ?? 0,
        onSave: _saveAttendance,
        isMobile: isMobile,
      ),
    );
  }
}