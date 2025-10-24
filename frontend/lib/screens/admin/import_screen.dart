import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:attendance_system/widgets/head/head_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;

  Future<void> _importExcel() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          final excel = Excel.decodeBytes(fileBytes);
          final sheet = excel.tables['Sheet1'];
          if (sheet == null) {
            throw Exception('Лист Sheet1 не найден в файле');
          }

          // Пропускаем первую строку как заголовок
          final students = <Map<String, dynamic>>[];
          for (var row in sheet.rows.skip(1)) {
            if (row.length >= 4) { // Убеждаемся, что есть минимум 4 столбца
              final surname = row[0]?.value?.toString().trim();
              final name = row[1]?.value?.toString().trim();
              final patronymic = row[2]?.value?.toString().trim();
              final groupId = row[3]?.value?.toString().trim();

              if (surname != null && name != null && groupId != null && surname.isNotEmpty && name.isNotEmpty) {
                // Формируем fullName (с отчеством, если оно есть)
                final fullName = [surname, name, patronymic].where((part) => part != null && part.isNotEmpty).join(' ');
                students.add({'fullName': fullName, 'groupId': groupId});
              } else {
                print('Пропущена строка с некорректными данными: $surname, $name, $patronymic, $groupId');
              }
            } else {
              print('Пропущена строка с недостаточным количеством столбцов: $row');
            }
          }

          if (students.isEmpty) {
            throw Exception('Нет данных студентов в файле');
          }

          // Предварительная проверка существующих студентов
          final existingStudents = await ApiService.getAdminStudents();
          final existingKeys = existingStudents.map((s) => '${s['fullName']}_${s['groupId']}').toSet();
          final newStudents = students.where((student) {
            final key = '${student['fullName']}_${student['groupId']}';
            return !existingKeys.contains(key);
          }).toList();

          if (newStudents.isEmpty) {
            throw Exception('Все студенты уже существуют в базе');
          }

          // Разбиение на пакеты и импорт
          const batchSize = 100;
          for (int i = 0; i < newStudents.length; i += batchSize) {
            final batch = newStudents.sublist(
              i,
              i + batchSize > newStudents.length ? newStudents.length : i + batchSize,
            );
            final adminProvider = Provider.of<AdminProvider>(context, listen: false);
            await adminProvider.importStudents(batch, context: context);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Импортировано ${newStudents.length} новых студентов')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка: Не удалось прочитать файл')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта Excel: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    Widget? drawerWidget;
    if (authProvider.isHead) {
      drawerWidget = const HeadHomeDrawer();
    } else if (authProvider.isAdmin) {
      drawerWidget = const AdminHomeDrawer();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт данных'),
        elevation: 2,
        backgroundColor: Colors.white,
      ),
      drawer: drawerWidget,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Выбрать и импортировать Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _importExcel,
                    ),
              const SizedBox(height: 16),
              const Text(
                'Выберите файл Excel (.xlsx или .xls) с данными студентов в формате: Фамилия, Имя, Отчество, Группа (отчество может отсутствовать).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}