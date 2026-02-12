// frontend/lib/screens/admin/export_screen.dart
import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/screens/analytics/models/academic_range.dart';
import 'package:attendance_system/screens/analytics/logic/date_ranges.dart'; // ✅ путь к твоему файлу
import 'package:attendance_system/screens/analytics/widgets/date_filter_bar.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/group.dart';
import '../../models/student.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = false;
  bool _isLoading = false;
  List<Group> _groups = [];
  String? _selectedGroupId;
  Map<String, List<Student>> _groupStudents = {};
  Map<String, Map<String, Map<String, String>>> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await groupsProvider.fetchGroups();
      await attendanceProvider.fetchStudents();
      await attendanceProvider.fetchAttendance();

      setState(() {
        _groups = groupsProvider.groups;
        _groupStudents = {
          for (var group in _groups)
            group.id: attendanceProvider.students.where((s) => s.groupId == group.id).toList(),
        };
        _attendanceStatus = {
          for (var group in _groups)
            group.id: {
              for (var student in _groupStudents[group.id] ?? [])
                student.id: _getStudentStatuses(student, attendanceProvider),
            },
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить данные'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, String> _getStudentStatuses(Student student, AttendanceProvider attendanceProvider) {
    final dates = _isRange
        ? _generateDateRange(_startDate!, _endDate!)
        : [DateFormat('yyyy-MM-dd').format(_startDate!)];
    final statuses = <String, String>{};
    for (var date in dates) {
      final attendance = attendanceProvider.getStudentAttendance(student.id, date);
      statuses[date] = attendance.isPresent
          ? 'Присутствует'
          : attendance.isAbsent
              ? 'Отсутствует'
              : attendance.isSick
                  ? 'Больничный'
                  : attendance.isIThub
                      ? 'Уважительная'
                      : 'Не отмечено';
    }
    return statuses;
  }

  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    for (var date = start;
        date.isBefore(end.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      // исключаем выходные
      if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
        dates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    }
    return dates;
  }

  Future<void> _exportToExcel() async {
  setState(() => _isLoading = true);
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // ✅ Заголовки (теперь через TextCellValue)
    sheet.appendRow([
      TextCellValue('Группа'),
      TextCellValue('Студент'),
      TextCellValue('Дата'),
      TextCellValue('Статус'),
    ]);

    // Фильтр по выбранной группе
    final filteredGroups =
        _selectedGroupId == null ? _groups : [_groups.firstWhere((g) => g.id == _selectedGroupId)];

    for (var group in filteredGroups) {
      final students = _groupStudents[group.id] ?? [];
      for (var student in students) {
        final statuses = _attendanceStatus[group.id]?[student.id] ?? {};
        final dates = _isRange
            ? _generateDateRange(_startDate!, _endDate!)
            : [DateFormat('yyyy-MM-dd').format(_startDate!)];

        for (var date in dates) {
          final status = statuses[date] ?? 'Не отмечено';

          // ✅ Каждое значение теперь TextCellValue
          sheet.appendRow([
            TextCellValue(group.name),
            TextCellValue(student.fullName),
            TextCellValue(DateFormat('dd.MM.yyyy').format(DateTime.parse(date))),
            TextCellValue(status),
          ]);
        }
      }
    }

    // Сохранение файла
    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/attendance_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Excel файл сохранён во временную директорию'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {},
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  void _onFixedRangeSelected(AcademicRange? range) {
    if (range != null) {
      setState(() {
        _startDate = range.startDate;
        _endDate = range.endDate;
        _isRange = range.endDate != null;
      });
      _loadData();
    }
  }

  void _onManualRangeSelected(DateTime start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
      _isRange = end != null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final fixedRanges = generateFixedRanges(); // ✅ исправлено

    Widget? drawerWidget;
    if (authProvider.isHead) {
      drawerWidget = const HeadHomeDrawer();
    } else if (authProvider.isAdmin) {
      drawerWidget = const AdminHomeDrawer();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экспорт данных'),
        elevation: 2,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: drawerWidget,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildSkeletonLoader()
            : _groups.isEmpty
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateFilterBar(
                          isMobile: MediaQuery.of(context).size.width < 600,
                          startDate: _startDate,
                          endDate: _endDate,
                          isRange: _isRange,
                          fixedRanges: fixedRanges,
                          onFixedRangeSelected: _onFixedRangeSelected,
                          onManualRangeSelected: _onManualRangeSelected,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Группа',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: _selectedGroupId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все группы'),
                            ),
                            ..._groups.map((group) => DropdownMenuItem(
                                  value: group.id,
                                  child: Text(group.name),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedGroupId = value);
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Экспорт в Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: _exportToExcel,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Данные по группам',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedGroupId == null ? _groups.length : 1,
                          itemBuilder: (context, index) {
                            final group = _selectedGroupId == null
                                ? _groups[index]
                                : _groups.firstWhere((g) => g.id == _selectedGroupId);
                            final students = _groupStudents[group.id] ?? [];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                title: Text(
                                  group.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Студентов: ${students.length}'),
                                children: students.map((student) {
                                  return ExpansionTile(
                                    title: Text(student.fullName),
                                    children: _isRange
                                        ? _generateDateRange(_startDate!, _endDate!).map((date) {
                                            final formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.parse(date));
                                            final status =
                                                _attendanceStatus[group.id]?[student.id]?[date] ?? 'Не отмечено';
                                            return ListTile(
                                              title: Text(formattedDate),
                                              trailing: Text(
                                                status,
                                                style: TextStyle(
                                                  color: status == 'Присутствует'
                                                      ? Colors.green
                                                      : status == 'Отсутствует'
                                                          ? Colors.red
                                                          : status == 'Больничный'
                                                              ? Colors.blue
                                                              : status == 'Уважительная'
                                                                  ? Colors.orange
                                                                  : Colors.grey,
                                                ),
                                              ),
                                            );
                                          }).toList()
                                        : [DateFormat('yyyy-MM-dd').format(_startDate!)].map((date) {
                                            final formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.parse(date));
                                            final status =
                                                _attendanceStatus[group.id]?[student.id]?[date] ?? 'Не отмечено';
                                            return ListTile(
                                              title: Text(formattedDate),
                                              trailing: Text(
                                                status,
                                                style: TextStyle(
                                                  color: status == 'Присутствует'
                                                      ? Colors.green
                                                      : status == 'Отсутствует'
                                                          ? Colors.red
                                                          : status == 'Больничный'
                                                              ? Colors.blue
                                                          : status == 'Уважительная'
                                                              ? Colors.orange
                                                              : Colors.grey,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 50, color: Colors.white),
            const SizedBox(height: 24),
            Container(width: 150, height: 20, color: Colors.white),
            const SizedBox(height: 16),
            Column(
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 100,
                  color: Colors.white,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Не удалось загрузить данные',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
