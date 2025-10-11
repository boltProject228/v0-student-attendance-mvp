import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/groups_provider.dart';
import '../models/group.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../widgets/app_drawer.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Group? _selectedGroup;
  Subject? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    await groupsProvider.fetchGroups();
    await groupsProvider.fetchSubjects();
  }

  Future<void> _loadStudents() async {
    if (_selectedGroup == null) return;

    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.fetchStudents();
  }

  Future<void> _saveAttendance() async {
    if (_selectedGroup == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите группу и предмет')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    for (var entry in _attendanceStatus.entries) {
      final data = {
        'studentId': entry.key,
        'groupId': _selectedGroup!.id,
        'subjectId': _selectedSubject!.id,
        'date': _selectedDate.toIso8601String(),
        'status': entry.value,
        'updatedBy': authProvider.user!.id,
      };

      await attendanceProvider.createAttendance(data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Посещаемость сохранена'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _attendanceStatus.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Посещаемость'),
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<Group>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Группа',
                        border: OutlineInputBorder(),
                      ),
                      items: groupsProvider.groups.map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value;
                          _loadStudents();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Subject>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Предмет',
                        border: OutlineInputBorder(),
                      ),
                      items: groupsProvider.subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Дата: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedGroup == null
                  ? const Center(
                      child: Text('Выберите группу для отметки посещаемости'),
                    )
                  : _buildStudentsList(attendanceProvider.students),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _attendanceStatus.isEmpty ? null : _saveAttendance,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(List<Student> students) {
    final filteredStudents = students
        .where((s) => s.groupId == _selectedGroup!.id)
        .toList();

    if (filteredStudents.isEmpty) {
      return const Center(child: Text('Студенты не найдены'));
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: filteredStudents.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          final status = _attendanceStatus[student.id] ?? 'present';

          return ListTile(
            title: Text(student.fullName),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'present',
                  label: Text('П'),
                  icon: Icon(Icons.check),
                ),
                ButtonSegment(
                  value: 'absent',
                  label: Text('Н'),
                  icon: Icon(Icons.close),
                ),
                ButtonSegment(
                  value: 'sick',
                  label: Text('Б'),
                  icon: Icon(Icons.healing),
                ),
                ButtonSegment(
                  value: 'wsk',
                  label: Text('У'),
                  icon: Icon(Icons.event_note),
                ),
              ],
              selected: {status},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _attendanceStatus[student.id] = newSelection.first;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
