import 'package:attendance_system/models/group.dart';
import 'package:attendance_system/models/student.dart';
import 'package:attendance_system/providers/attendance_provider.dart';
import 'package:attendance_system/providers/groups_provider.dart';
import 'package:attendance_system/screens/analytics/logic/date_ranges.dart';
import 'package:intl/intl.dart';

Future<Map<String, dynamic>> calculateOverallAnalytics(
  AttendanceProvider attendanceProvider,
  GroupsProvider groupsProvider,
  DateTime? startDate,
  DateTime? endDate,
  bool isRange,
) async {
  final totalStudents = attendanceProvider.students.length;
  final totalGroups = groupsProvider.groups.length;

  double present = 0, absent = 0, sick = 0, ithub = 0;
  int totalRecords = 0; // Excludes sick

  final start = isRange ? startDate : startDate;
  final end = isRange ? endDate : startDate;
  final dates = isRange
      ? generateDateRange(start!, end!)
      : [DateFormat('yyyy-MM-dd').format(start!)];

  for (var group in groupsProvider.groups) {
    for (var date in dates) {
      final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
      present += (stats['present'] ?? 0) + (stats['ithub'] ?? 0); // Combine present and ithub
      absent += stats['absent'] ?? 0;
      sick += stats['sick'] ?? 0;
      totalRecords += (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['ithub'] ?? 0); // Exclude sick
    }
  }

  final total = totalRecords > 0 ? totalRecords : 1;
  final totalWithSick = total + sick; // For sick percentage

  return {
    'totalStudents': totalStudents,
    'totalGroups': totalGroups,
    'averagePresent': ((present + ithub) / total * 100).toStringAsFixed(1),
    'averageAbsent': (absent / total * 100).toStringAsFixed(1),
    'averageSick': totalWithSick > 0 ? (sick / totalWithSick * 100).toStringAsFixed(1) : '0.0',
    'averageIThub': (ithub / total * 100).toStringAsFixed(1),
    'countPresent': present.toInt(),
    'countAbsent': absent.toInt(),
    'countSick': sick.toInt(),
    'countIThub': ithub.toInt(),
  };
}

Future<List<Map<String, dynamic>>> calculateGroupAnalytics(
  AttendanceProvider attendanceProvider,
  GroupsProvider groupsProvider,
  DateTime? startDate,
  DateTime? endDate,
  bool isRange,
) async {
  final start = isRange ? startDate : startDate;
  final end = isRange ? endDate : startDate;
  final dates = isRange
      ? generateDateRange(start!, end!)
      : [DateFormat('yyyy-MM-dd').format(start!)];

  List<Map<String, dynamic>> groupData = [];
  for (var group in groupsProvider.groups) {
    double present = 0;
    double absent = 0;
    double sick = 0;
    double ithub = 0;
    int totalMarked = 0; // Excludes sick
    int studentCount = attendanceProvider.getGroupStudentCount(group.id);

    for (var date in dates) {
      final stats = attendanceProvider.getGroupAttendanceStats(group.id, date);
      present += stats['present'] ?? 0;
      absent += stats['absent'] ?? 0;
      sick += stats['sick'] ?? 0;
      ithub += stats['ithub'] ?? 0;
      totalMarked += (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['ithub'] ?? 0); // Exclude sick
    }

    final total = totalMarked > 0 ? totalMarked : 1;
    final totalWithSick = total + sick; // For sick percentage
    final attendancePercent = ((present + ithub) / total * 100).toStringAsFixed(1);

    groupData.add({
      'groupId': group.id,
      'name': group.name,
      'specialty': group.specialty,
      'course': group.course,
      'percent': attendancePercent,
      'studentCount': studentCount,
      'presentCount': present.toInt(),
      'absentCount': absent.toInt(),
      'sickCount': sick.toInt(),
      'ithubCount': ithub.toInt(),
      'markedCount': totalMarked,
      'numDays': dates.length,
    });
  }

  return groupData;
}

Future<List<Map<String, dynamic>>> calculateStudentAnalytics(
  AttendanceProvider attendanceProvider,
  GroupsProvider groupsProvider,
  DateTime? startDate,
  DateTime? endDate,
  bool isRange,
) async {
  final start = isRange ? startDate : startDate;
  final end = isRange ? endDate : startDate;
  final dates = isRange
      ? generateDateRange(start!, end!)
      : [DateFormat('yyyy-MM-dd').format(start!)];

  final groupMap = {for (var group in groupsProvider.groups) group.id: group};

  List<Map<String, dynamic>> studentData = [];
  for (var student in attendanceProvider.students) {
    double present = 0;
    int totalRecords = 0; // Excludes sick
    for (var date in dates) {
      final attendance = attendanceProvider.getStudentAttendance(student.id, date);
      if (attendance.status != 'unmarked' && attendance.status != 'sick') {
        totalRecords++;
        if (attendance.status == 'present' || attendance.status == 'ithub') {
          present++;
        }
      }
    }
    final total = totalRecords > 0 ? totalRecords : 1;
    final percent = (present / total * 100).toStringAsFixed(1);

    final String groupName = groupMap[student.groupId]?.name ?? 'Группа не указана';

    studentData.add({
      'studentId': student.id,
      'fullName': student.fullName,
      'groupId': student.groupId,
      'groupName': groupName,
      'percent': percent,
    });
  }

  return studentData;
}