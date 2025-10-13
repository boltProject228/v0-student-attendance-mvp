import '../models/group.dart';
import '../models/student.dart';
import '../models/subject.dart';
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
  ];

  // ✅ Mock login
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


// Mock groups
static List<Group> mockGetGroups() {
  return [
    // 1 курс
    Group(id: 'g1', name: 'ТЭ-115(Ру)', specialty: 'ТЭ(Ру)', course: 1, createdAt: DateTime.now()),
    Group(id: 'g2', name: 'БКЕ-115', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g3', name: 'БКЕ-125', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g4', name: 'БКЕ-135', specialty: 'БҚЕ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g5', name: 'ПО-115', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g6', name: 'ПО-145', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g7', name: 'ПО-155', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g8', name: 'ПО-165', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g9', name: 'ПО-175', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g10', name: 'ПО-185', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g11', name: 'ПО-195', specialty: 'ПО', course: 1, createdAt: DateTime.now()),
    Group(id: 'g12', name: 'СИБ-134', specialty: 'СИБ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g13', name: 'СИБ-135', specialty: 'СИБ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g14', name: 'АКЖ-115', specialty: 'АҚЖ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g15', name: 'АКЖ-125', specialty: 'АҚЖ', course: 1, createdAt: DateTime.now()),
    Group(id: 'g16', name: 'M-115(Қаз)', specialty: 'М(Қаз)', course: 1, createdAt: DateTime.now()),
    Group(id: 'g17', name: 'M-125(Ру)', specialty: 'М(Ру)', course: 1, createdAt: DateTime.now()),
    Group(id: 'g18', name: 'M-135(Ру)', specialty: 'М(Ру)', course: 1, createdAt: DateTime.now()),

    // 2 курс
    Group(id: 'g19', name: 'ТЭ-214(Ру)', specialty: 'ТЭ(Ру)', course: 2, createdAt: DateTime.now()),
    Group(id: 'g20', name: 'БКЕ-214', specialty: 'БҚЕ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g21', name: 'БКЕ-224', specialty: 'БҚЕ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g22', name: 'ПО-234', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g23', name: 'ПО-244', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g24', name: 'ПО-254', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g25', name: 'ПО-264', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g26', name: 'ПО-274', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g27', name: 'ПО-284', specialty: 'ПО', course: 2, createdAt: DateTime.now()),
    Group(id: 'g28', name: 'СИБ-224', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g29', name: 'СИБ-234', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g30', name: 'СИБ-244', specialty: 'СИБ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g31', name: 'АКЖ-214', specialty: 'АҚЖ', course: 2, createdAt: DateTime.now()),
    Group(id: 'g32', name: 'M-214(Қаз)', specialty: 'М(Қаз)', course: 2, createdAt: DateTime.now()),
    Group(id: 'g33', name: 'M-224(Ру)', specialty: 'М(Ру)', course: 2, createdAt: DateTime.now()),
    Group(id: 'g34', name: 'M-234(Ру)', specialty: 'М(Ру)', course: 2, createdAt: DateTime.now()),

    // 3 курс
    Group(id: 'g35', name: 'ТЭ-313(Ру)', specialty: 'ТЭ(Ру)', course: 3, createdAt: DateTime.now()),
    Group(id: 'g36', name: 'ТЭ-323(Ру)', specialty: 'ТЭ(Ру)', course: 3, createdAt: DateTime.now()),
    Group(id: 'g37', name: 'БҚЕ-313', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
    Group(id: 'g38', name: 'БКЕ-323', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
    Group(id: 'g39', name: 'БКЕ-333', specialty: 'БҚЕ', course: 3, createdAt: DateTime.now()),
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

    // 4 курс
    Group(id: 'g58', name: 'ТЭ-422(Ру)', specialty: 'ТЭ(Ру)', course: 4, createdAt: DateTime.now()),
  ];
}


  // Mock students (with groupId references)
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
    Student(id: 's1', fullName: 'Ivan Ivanov', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's2', fullName: 'Maria Petrova', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's3', fullName: 'Alex Sidorov', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's4', fullName: 'Olga Smirnova', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's5', fullName: 'Dmitry Orlov', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's6', fullName: 'Elena Volkova', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's7', fullName: 'Sergey Pavlov', groupId: 'g2', createdAt: DateTime.now()),
    Student(id: 's8', fullName: 'Anna Morozova', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's9', fullName: 'Nikolay Kuznetsov', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's10', fullName: 'Tatiana Lebedeva', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's11', fullName: 'Pavel Egorov', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's12', fullName: 'Irina Fedorova', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's13', fullName: 'Maxim Nikitin', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's14', fullName: 'Ekaterina Zaitseva', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's15', fullName: 'Andrey Mikhailov', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's16', fullName: 'Svetlana Popova', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's17', fullName: 'Roman Belov', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's18', fullName: 'Natalia Vinogradova', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's19', fullName: 'Vladimir Korolev', groupId: 'g1', createdAt: DateTime.now()),
    Student(id: 's20', fullName: 'Yulia Sorokina', groupId: 'g1', createdAt: DateTime.now()),
  ];
}

  // Mock attendance
  static List<Attendance> mockGetAttendance() {
    return [
      Attendance(
        id: 'a1',
        studentId: 's1',
        groupId: 'g1',

        date: DateTime.now(),
        status: 'present',
        updatedBy: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Attendance(
        id: 'a2',
        studentId: 's2',
        groupId: 'g1',
 
        date: DateTime.now(),
        status: 'absent',
        updatedBy: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // ✅ Конвертация моков в объекты User
  static List<User> mockGetUsers() {
    return mockUsersData.map((data) => User.fromJson(data)).toList();
  }
}