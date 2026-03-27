import 'package:intl/intl.dart';

import '../models/group.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/user.dart';

class MockData {
  static final List<Map<String, dynamic>> mockUsersData = [
    {
      'id': '1',
      'login': 'teacher',
      'role': 'teacher',
      'createdAt': DateTime.now().toIso8601String(),
      'settings': {
        'theme': 'light',
        'language': 'ru',
        'notifications': true,
      },
      'firstName': 'Ерсултан',
      'lastName': 'Базарбай',
    },
    {
      'id': '2',
      'login': 'head',
      'role': 'head',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'settings': {
        'theme': 'dark',
        'language': 'ru',
        'notifications': false,
      },
      'firstName': 'Серик',
      'lastName': 'Абдурахманов',
    },
    {
      'id': '3',
      'login': 'teacher_02',
      'role': 'teacher',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'settings': {
        'theme': 'dark',
        'language': 'kz',
        'notifications': false,
      },
      'firstName': 'Айгерим',
      'lastName': 'Нуртаева',
    },

    {
      'id': '4',
      'login': 'teacher_02',
      'role': 'admin',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'settings': {
        'theme': 'dark',
        'language': 'kz',
        'notifications': false,
      },
      'firstName': 'Admin',
      'lastName': 'Admin',
    }
  ];

  static Map<String, dynamic> mockLogin(String login, String password) {
    final user = mockUsersData.firstWhere(
      (u) => u['login'] == login,
      orElse: () => throw Exception('Invalid credentials'),
    );

    if (password != 'pass123') throw Exception('Invalid credentials');

    return {
      'token': 'mock_token_$login',
      'user': user,
    };
  }

  static List<Group> mockGetGroups() {
    return [
      Group(id: 'g1', name: 'ТЭ-115(Ру)', specialty: 'ТЭ(Ру)', course: 1, createdAt: DateTime.now()),
      Group(id: 'g2', name: 'БҚЕ-115', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g3', name: 'БҚЕ-125', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g4', name: 'БҚЕ-135', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g5', name: 'ПО-115', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g6', name: 'ПО-145', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g7', name: 'ПО-155', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g8', name: 'ПО-165', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g9', name: 'ПО-175', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g10', name: 'ПО-185', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g11', name: 'ПО-195', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
      Group(id: 'g12', name: 'СИБ-134', specialty: 'СИБ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g13', name: 'СИБ-135', specialty: 'СИБ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g14', name: 'АҚЖ-115', specialty: 'АҚЖ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g15', name: 'АҚЖ-125', specialty: 'АҚЖ', course: 1, createdAt: DateTime.now()),
      Group(id: 'g16', name: 'M-115(Қаз)', specialty: 'М(Қаз)', course: 1, createdAt: DateTime.now()),
      Group(id: 'g17', name: 'M-125(Ру)', specialty: 'М(Ру)', course: 1, createdAt: DateTime.now()),
      Group(id: 'g18', name: 'M-135(Ру)', specialty: 'М(Ру)', course: 1, createdAt: DateTime.now()),
      Group(id: 'g19', name: 'ТЭ-214(Ру)', specialty: 'ТЭ(Ру)', course: 2, createdAt: DateTime.now()),
      Group(id: 'g20', name: 'БҚЕ-214', specialty: 'БҚЕ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g21', name: 'БҚЕ-224', specialty: 'БҚЕ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g22', name: 'ПО-234', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g23', name: 'ПО-244', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g24', name: 'ПО-254', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g25', name: 'ПО-264', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g26', name: 'ПО-274', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g27', name: 'ПО-284', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
      Group(id: 'g28', name: 'СИБ-224', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g29', name: 'СИБ-234', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g30', name: 'СИБ-244', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g31', name: 'АҚЖ-214', specialty: 'АҚЖ', course: 2, createdAt: DateTime.now()),
      Group(id: 'g32', name: 'M-214(Қаз)', specialty: 'М(Қаз)', course: 2, createdAt: DateTime.now()),
      Group(id: 'g33', name: 'M-224(Ру)', specialty: 'М(Ру)', course: 2, createdAt: DateTime.now()),
      Group(id: 'g34', name: 'M-234(Ру)', specialty: 'М(Ру)', course: 2, createdAt: DateTime.now()),
      Group(id: 'g35', name: 'ТЭ-313(Ру)', specialty: 'ТЭ(Ру)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g36', name: 'ТЭ-323(Ру)', specialty: 'ТЭ(Ру)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g37', name: 'БҚЕ-313', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g38', name: 'БҚЕ-323', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g39', name: 'БҚЕ-333', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g40', name: 'ПО-303', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g41', name: 'ПО-313', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g42', name: 'ПО-323', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g43', name: 'ПО-333', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g44', name: 'ПО-343', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g45', name: 'ПО-353', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g46', name: 'ПО-363', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g47', name: 'ПО-373', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g48', name: 'ПО-383', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g49', name: 'ПО-393', specialty: 'ПО', course: 3, createdAt: DateTime.now()),
      Group(id: 'g50', name: 'СИБ-313', specialty: 'СИБ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g51', name: 'СИБ-323', specialty: 'СИБ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g52', name: 'СИБ-333', specialty: 'СИБ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g53', name: 'АҚЖ-313', specialty: 'АҚЖ', course: 3, createdAt: DateTime.now()),
      Group(id: 'g54', name: 'M-313(Қаз)', specialty: 'М(Қаз)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g55', name: 'M-323(Ру)', specialty: 'М(Ру)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g56', name: 'M-333(Ру)', specialty: 'М(Ру)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g57', name: 'M-343(Ру)', specialty: 'М(Ру)', course: 3, createdAt: DateTime.now()),
      Group(id: 'g58', name: 'ТЭ-422(Ру)', specialty: 'ТЭ(Ру)', course: 4, createdAt: DateTime.now()),
    ];
  }

  static List<Student> mockGetStudents() {
    return [
      Student(id: 's1', fullName: 'Ivan Ivanov', groupId: 'g21', createdAt: DateTime.now()),
      Student(id: 's2', fullName: 'Maria Petrova', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's3', fullName: 'Alex Sidorov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's4', fullName: 'Olga Smirnova', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's5', fullName: 'Dmitry Orlov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's6', fullName: 'Elena Volkova', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's7', fullName: 'Sergey Pavlov', groupId: 'g2', createdAt: DateTime.now()), 
      

      Student(id: 's8', fullName: 'Anna Morozova', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's9', fullName: 'Nikolay Kuznetsov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's10', fullName: 'Tatiana Lebedeva', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's11', fullName: 'Pavel Egorov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's12', fullName: 'Irina Fedorova', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's13', fullName: 'Maxim Nikitin', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's14', fullName: 'Ekaterina Zaitseva', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's15', fullName: 'Andrey Mikhailov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's16', fullName: 'Svetlana Popova', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's17', fullName: 'Roman Belov', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's18', fullName: 'Natalia Vinogradova', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's19', fullName: 'Vladimir Korolev', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's20', fullName: 'Yulia Sorokina', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's21', fullName: 'Ivan Ivanov2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's22', fullName: 'Maria Petrova2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's23', fullName: 'Alex Sidorov2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's24', fullName: 'Olga Smirnova2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's25', fullName: 'Dmitry Orlov2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's26', fullName: 'Elena Volkova2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's27', fullName: 'Sergey Pavlov2', groupId: 'g2', createdAt: DateTime.now()),
      Student(id: 's28', fullName: 'Anna Morozova2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's29', fullName: 'Nikolay Kuznetsov2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's30', fullName: 'Tatiana Lebedeva2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's31', fullName: 'Pavel Egorov2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's32', fullName: 'Irina Fedorova2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's33', fullName: 'Maxim Nikitin2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's34', fullName: 'Ekaterina Zaitseva2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's35', fullName: 'Andrey Mikhailov2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's36', fullName: 'Svetlana Popova2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's37', fullName: 'Roman Belov2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's38', fullName: 'Natalia Vinogradova2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's39', fullName: 'Vladimir Korolev2', groupId: 'g1', createdAt: DateTime.now()),
      Student(id: 's40', fullName: 'Yulia Sorokina2', groupId: 'g1', createdAt: DateTime.now()),
    ];
  }

  static List<Attendance> mockGetAttendance() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      Attendance(
        id: 'a1',
        studentId: 's1',
        groupId: 'g21',
        date: today,
        status: 'present',
        updatedBy: '1',
        createdAt: today,
        updatedAt: today,
      ),
      Attendance(
        id: 'a2',
        studentId: 's2',
        groupId: 'g1',
        date: today,
        status: 'absent',
        updatedBy: '1',
        createdAt: today,
        updatedAt: today,
      ),
      Attendance(
        id: 'a3',
        studentId: 's3',
        groupId: 'g2',
        date: today,
        status: 'sick',
        updatedBy: '1',
        createdAt: today,
        updatedAt: today,
      ),
      Attendance(
        id: 'a4',
        studentId: 's4',
        groupId: 'g1',
        date: today,
        status: 'ithub',
        updatedBy: '1',
        createdAt: today,
        updatedAt: today,
      ),
      Attendance(
        id: 'a5',
        studentId: 's1',
        groupId: 'g21',
        date: yesterday,
        status: 'present',
        updatedBy: '1',
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
      Attendance(
        id: 'a6',
        studentId: 's2',
        groupId: 'g1',
        date: yesterday,
        status: 'present',
        updatedBy: '1',
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
      Attendance(
        id: 'a7',
        studentId: 's3',
        groupId: 'g2',
        date: yesterday,
        status: 'absent',
        updatedBy: '1',
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
      Attendance(
        id: 'a8',
        studentId: 's4',
        groupId: 'g1',
        date: yesterday,
        status: 'sick',
        updatedBy: '1',
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
    ];
  }

  static List<User> mockGetUsers() {
    return mockUsersData.map((data) => User.fromJson(data)).toList();
  }

  static Map<String, dynamic> mockGetAnalytics({DateTime? startDate, DateTime? endDate}) {
    final attendance = mockGetAttendance();
    final students = mockGetStudents();
    final groups = mockGetGroups();

    double present = 0, absent = 0, sick = 0, ithub = 0;
    int totalRecords = 0;

    final start = startDate ?? DateTime.now();
    final end = endDate ?? start;
    final dates = <String>[];
    for (var date = start; date.isBefore(end.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    for (var date in dates) {
      final records = attendance.where((a) => a.date.toIso8601String().split('T')[0] == date).toList();
      for (var record in records) {
        if (record.isPresent) present++;
        if (record.isAbsent) absent++;
        if (record.isSick) sick++;
        if (record.isIThub) ithub++;
        totalRecords++;
      }
    }

    final total = totalRecords > 0 ? totalRecords : 1; // Avoid division by zero
    return {
      'totalStudents': students.length,
      'totalGroups': groups.length,
      'averagePresent': (present / total * 100).toStringAsFixed(1),
      'averageAbsent': (absent / total * 100).toStringAsFixed(1),
      'averageSick': (sick / total * 100).toStringAsFixed(1),
      'averageIThub': (ithub / total * 100).toStringAsFixed(1),
    };
  }
}