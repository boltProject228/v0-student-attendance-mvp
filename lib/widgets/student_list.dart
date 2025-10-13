// lib/widgets/student_list.dart
import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/student.dart';

class StudentList extends StatefulWidget {
  final List<Student> students;
  final Group selectedGroup;
  final VoidCallback onClose;
  final Future<void> Function() onSave; // Callback для сохранения

  const StudentList({
    super.key,
    required this.students,
    required this.selectedGroup,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final Map<String, String> _attendanceStatus = {}; // Локальный status

  // Кнопка статуса для wide screen
  Widget _buildStatusButton(
    String value,
    IconData icon,
    String tooltip,
    String currentStatus,
    String studentId,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: currentStatus == value ? Colors.blue[700] : Colors.grey[600]),
        onPressed: () {
          setState(() {
            _attendanceStatus[studentId] = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Студенты группы ${widget.selectedGroup.name}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final status = _attendanceStatus[student.id] ?? 'present';

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0, vertical: 4.0),
                  title: Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: isMobile
                      ? null // Убрали subtitle на мобильных для компактности
                      : Text('Группа: ${widget.selectedGroup.name}', style: Theme.of(context).textTheme.bodySmall),
                  trailing: isWideScreen
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusButton('present', Icons.check, 'Присутствует', status, student.id),
                            _buildStatusButton('absent', Icons.close, 'Отсутствует', status, student.id),
                            _buildStatusButton('sick', Icons.healing, 'Больничный', status, student.id),
                            _buildStatusButton('wsk', Icons.access_time, 'WSK', status, student.id),
                            _buildStatusButton('respect', Icons.event_note, 'Уважительная', status, student.id),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'present', icon: Icon(Icons.check), tooltip: 'Присутствует'),
                              ButtonSegment(value: 'absent', icon: Icon(Icons.close), tooltip: 'Отсутствует'),
                              ButtonSegment(value: 'sick', icon: Icon(Icons.healing), tooltip: 'Больничный'),
                              ButtonSegment(value: 'wsk', icon: Icon(Icons.access_time), tooltip: 'WSK'),
                              ButtonSegment(value: 'respect', icon: Icon(Icons.event_note), tooltip: 'Уважительная'),
                            ],
                            selected: {status},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _attendanceStatus[student.id] = newSelection.first;
                              });
                            },
                            showSelectedIcon: false, // Компактно для мобильных
                          ),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: FilledButton(
              onPressed: _attendanceStatus.isEmpty ? null : widget.onSave,
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, isMobile ? 48 : 56), // Больше кнопка на мобильных
              ),
              child: const Text('Сохранить отметки'),
            ),
          ),
        ],
      ),
    );
  }
}