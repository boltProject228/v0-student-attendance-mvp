import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/group.dart';
import '../../models/student.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/head/head_home_drawer.dart';

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
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return dates;
  }

  void _exportToExcel() {
    // Заглушка для экспорта
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Экспорт в Excel (заглушка)')),
    );
    // В будущем: использовать пакет excel
    // Формат: Группа | Студент | Дата | Статус
  }

  @override
  Widget build(BuildContext context) {
    final dates = _isRange
        ? _generateDateRange(_startDate!, _endDate!)
        : [DateFormat('dd.MM.yyyy').format(_startDate!)];
    
     final authProvider = Provider.of<AuthProvider>(context);

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
                        // Фильтр по датам
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 20),
                                label: Text(
                                  _isRange
                                      ? '${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Выберите'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Выберите'}'
                                      : _startDate != null
                                          ? DateFormat('dd.MM.yyyy').format(_startDate!)
                                          : 'Выберите дату',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  if (_isRange) {
                                    final pickedRange = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.blue.shade600,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: Colors.black,
                                            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (pickedRange != null) {
                                      setState(() {
                                        _startDate = pickedRange.start;
                                        _endDate = pickedRange.end;
                                      });
                                      _loadData();
                                    }
                                  } else {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                      _loadData();
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Switch(
                              value: _isRange,
                              onChanged: (value) {
                                setState(() {
                                  _isRange = value;
                                  if (!value) _endDate = null;
                                });
                                _loadData();
                              },
                            ),
                            const Text('Диапазон'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Фильтр по группам
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
                        // Кнопка экспорта
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
                        // Список групп и студентов
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
                            final group = _selectedGroupId == null ? _groups[index] : _groups.firstWhere((g) => g.id == _selectedGroupId);
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
                                    children: dates.map((date) {
                                      final formattedDate = _isRange
                                          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(date))
                                          : date;
                                      final status = _attendanceStatus[group.id]?[student.id]?[date] ?? 'Не отмечено';
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
            Container(
              width: double.infinity,
              height: 50,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 20,
              color: Colors.white,
            ),
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
          const Text(
            'Не удалось загрузить данные',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
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