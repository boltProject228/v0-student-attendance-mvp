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
  String? lastUpdatedByName;
  String? lastUpdatedByRole;
  DateTime? lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchStudents();
    _loadExistingAttendances();
  }

  Future<void> _loadExistingAttendances() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // 🚀 Принудительное обновление для получения актуальных данных перед отображением
    await provider.fetchAttendance(groupId: widget.group.id, date: today, forceRefresh: true);
    
    final attendances = await provider.getAttendances(widget.group.id, today);
    
    DateTime? maxUpdatedAt;
    Attendance? lastAttendance;

    for (var att in provider.attendanceList.where((a) =>
        a.groupId == widget.group.id &&
        DateFormat('yyyy-MM-dd').format(a.date) == today)) {
      // Ищем самую последнюю отметку по времени обновления
      if (maxUpdatedAt == null || att.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = att.updatedAt;
        lastAttendance = att;
      }
    }

    if (!mounted) return;

    setState(() {
      _statuses.clear();
      _attIds.clear();
      for (var entry in attendances.entries) {
        _statuses[entry.key] = entry.value['status']!;
        _attIds[entry.key] = entry.value['id']!;
      }
      if (lastAttendance != null) {
        lastUpdatedByName = lastAttendance.updatedByName; 
        lastUpdatedByRole = lastAttendance.updatedByRole;
        
        // ✅ ИСПРАВЛЕНИЕ ВРЕМЕНИ: Преобразуем UTC дату из базы данных в локальное время устройства
        lastUpdatedAt = lastAttendance.updatedAt.toLocal(); 
        
      } else {
        lastUpdatedByName = null;
        lastUpdatedByRole = null;
        lastUpdatedAt = null;
      }
    });
  }
  
  // ✅ НОВАЯ ФУНКЦИЯ: Преобразует роль с английского на русский
  String _mapRoleToRussian(String? role) {
    if (role == null) return '';
    switch (role?.toLowerCase()) {
      case 'head':
        return 'заведующий';
      case 'teacher':
        return 'преподаватель';
      case 'admin':
        return 'администратор';
      default:
        // Возвращаем исходную роль, если она не найдена
        return role ?? ''; 
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
    final students =
        provider.students.where((s) => s.groupId == widget.group.id).toList();

    for (final student in students) {
      final status = _statuses[student.id] ?? 'unmarked';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final students =
        provider.students.where((s) => s.groupId == widget.group.id).toList();
    final studentCount = students.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ✅ ИСПОЛЬЗОВАНИЕ: Преобразуем роль для отображения
    final displayRole = _mapRoleToRussian(lastUpdatedByRole);
    
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
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Всего: $studentCount',
                          style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.black54),
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
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        'Всего: $studentCount',
                        style: const TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (lastUpdatedByName != null &&
              lastUpdatedByRole != null &&
              lastUpdatedAt != null)
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 16.0, vertical: 6.0),
              child: Text(
                // ✅ ИСПОЛЬЗОВАНИЕ displayRole для русского названия
                'Обновлено: $lastUpdatedByName ($displayRole) в ${DateFormat('HH:mm dd.MM.yyyy').format(lastUpdatedAt!)}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: Colors.grey,
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6.0 : 16.0, vertical: 6.0),
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final status = _statuses[student.id] ?? 'unmarked';
                  return AttendanceTile(
                    index: index + 1,
                    name: student.fullName,
                    status: status,
                    onStatusChange: (newStatus) {
                      setState(() => _statuses[student.id] = newStatus);
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

  Future<void> _saveAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final today = DateTime.now(); // Используем DateTime.now() для проверки дня недели

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ошибка: пользователь не аутентифицирован'),
            backgroundColor: Colors.red),
      );
      return;
    }
    
    // 🛑 Блокировка сохранения в выходные дни (Суббота: 6, Воскресенье: 7)
    if (today.weekday == DateTime.saturday || today.weekday == DateTime.sunday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нельзя редактировать отметки в выходные дни (суббота и воскресенье).'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Прерываем выполнение
    }

    // Нормализация даты к началу дня UTC для корректного сохранения в базе
    final dateUtc = DateTime.utc(today.year, today.month, today.day).toIso8601String(); 

    bool success = true;

    for (var entry in _statuses.entries) {
      String studentId = entry.key;
      String status = entry.value;
      
      var data = {
        'studentId': studentId,
        'groupId': widget.group.id,
        'date': dateUtc, // Используем нормализованную UTC дату
        'updatedBy': authProvider.user!.id,
      };

      String? attId = _attIds[studentId];

      if (status == 'unmarked' || status.isEmpty) {
        if (attId != null) {
          if (!await provider.deleteAttendance(attId)) success = false;
          setState(() {
            _attIds.remove(studentId);
            _statuses[studentId] = 'unmarked';
          });
        }
      } else {
        data['status'] = status;
        if (attId != null) {
          if (!await provider.updateAttendance(attId, data)) success = false;
        } else {
          String? newId = await provider.createAttendance(data);
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

    // Обновляем UI после сохранения, чтобы получить актуальные данные о последнем обновлении
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
      
      // Возвращаем `true` для сигнализации родительскому экрану о необходимости обновления аналитики
      if (success) Navigator.pop(context, true); 
    }
  }
}