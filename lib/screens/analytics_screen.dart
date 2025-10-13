import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getAnalytics();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
              ? const Center(child: Text('Нет данных'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Всего студентов',
                              _analyticsData!['totalStudents']?.toString() ?? '0',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Всего групп',
                              _analyticsData!['totalGroups']?.toString() ?? '0',
                              Icons.groups,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Всего предметов',
                              _analyticsData!['totalSubjects']?.toString() ?? '0',
                              Icons.book,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Средняя посещаемость',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildAttendanceBar(
                                'Присутствовали',
                                _analyticsData!['averagePresent'] ?? 0,
                                Colors.green,
                              ),
                              const SizedBox(height: 8),
                              _buildAttendanceBar(
                                'Отсутствовали',
                                _analyticsData!['averageAbsent'] ?? 0,
                                Colors.red,
                              ),
                              const SizedBox(height: 8),
                              _buildAttendanceBar(
                                'Больничные',
                                _analyticsData!['averageSick'] ?? 0,
                                Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              _buildAttendanceBar(
                                'Уважительные',
                                _analyticsData!['averageWsk'] ?? 0,
                                Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const StudentAnalyticsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 20,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class StudentAnalyticsList extends StatefulWidget {
  const StudentAnalyticsList({super.key});

  @override
  State<StudentAnalyticsList> createState() => _StudentAnalyticsListState();
}

class _StudentAnalyticsListState extends State<StudentAnalyticsList> {
  String? _selectedStudentId;
  List<dynamic> _studentAnalytics = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchStudents();
  }

  Future<void> _loadStudentAnalytics(String studentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getStudentAnalytics(studentId);
      setState(() {
        _studentAnalytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Аналитика по студентам',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStudentId,
              decoration: const InputDecoration(
                labelText: 'Выберите студента',
                border: OutlineInputBorder(),
              ),
              items: adminProvider.students.map((student) {
                return DropdownMenuItem(
                  value: student.id,
                  child: Text(student.fullName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                  _loadStudentAnalytics(value);
                }
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_studentAnalytics.isEmpty && _selectedStudentId != null)
              const Center(child: Text('Нет данных'))
            else if (_studentAnalytics.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _studentAnalytics.length,
                itemBuilder: (context, index) {
                  final item = _studentAnalytics[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item['subjectName'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Присутствовал: ${item['present'] ?? 0}'),
                          Text('Отсутствовал: ${item['absent'] ?? 0}'),
                          Text('Больничный: ${item['sick'] ?? 0}'),
                          Text('Уважительная: ${item['wsk'] ?? 0}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
