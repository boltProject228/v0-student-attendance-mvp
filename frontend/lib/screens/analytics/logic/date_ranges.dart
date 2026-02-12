import 'package:intl/intl.dart';
import '../models/academic_range.dart';

List<String> generateDateRange(DateTime start, DateTime end) {
  final dates = <String>[];
  for (var date = start; date.isBefore(end.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
    if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }
  }
  return dates;
}

List<AcademicRange> generateFixedRanges() {
  const int semester1StartMonth = 9;
  const int semester1StartDay = 2;
  const int semester1EndMonth = 1;
  const int semester1EndDay = 15;

  const int semester2StartMonth = 2;
  const int semester2StartDay = 1;
  const int semester2EndMonth = 6;
  const int semester2EndDay = 30;

  final now = DateTime.now();
  List<AcademicRange> ranges = [];

  ranges.add(AcademicRange(label: 'Сегодня', startDate: now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)));

  int acYearStart = now.month >= semester1StartMonth ? now.year : now.year - 1;
  int acYearEnd = acYearStart + 1;

  DateTime iStart = DateTime(acYearStart, semester1StartMonth, semester1StartDay);
  DateTime iEnd = DateTime(acYearEnd, semester1EndMonth, semester1EndDay);
  String iLabel = 'I семестр ($acYearStart/$acYearEnd)';
  ranges.add(AcademicRange(label: iLabel, startDate: iStart, endDate: iEnd));

  DateTime month = DateTime(acYearStart, 9, 1);
  while (month.isBefore(iEnd.add(const Duration(days: 1)))) {
    DateTime startOfMonth = month;
    DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0);
    DateTime finalEndDate = endOfMonth.isAfter(iEnd) ? iEnd : endOfMonth;
    String monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(startOfMonth);
    ranges.add(AcademicRange(label: monthLabel, startDate: startOfMonth, endDate: finalEndDate));
    month = _addMonth(month);
    if (month.isAfter(iEnd)) break;
  }

  DateTime iiStart = DateTime(acYearEnd, semester2StartMonth, semester2StartDay);
  DateTime iiEnd = DateTime(acYearEnd, semester2EndMonth, semester2EndDay);
  String iiLabel = 'II семестр ($acYearStart/$acYearEnd)';
  ranges.add(AcademicRange(label: iiLabel, startDate: iiStart, endDate: iiEnd));

  DateTime monthII = DateTime(acYearEnd, semester2StartMonth, 1);
  while (monthII.isBefore(iiEnd.add(const Duration(days: 1)))) {
    DateTime startOfMonth = monthII;
    DateTime endOfMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 0);
    DateTime finalEndDate = endOfMonth.isAfter(iiEnd) ? iiEnd : endOfMonth;
    String monthLabel = DateFormat('LLLL yyyy', 'ru_RU').format(startOfMonth);
    ranges.add(AcademicRange(label: monthLabel, startDate: startOfMonth, endDate: finalEndDate));
    monthII = _addMonth(monthII);
    if (monthII.isAfter(iiEnd)) break;
  }

  return ranges;
}

DateTime _addMonth(DateTime date) {
  int nextMonth = date.month + 1;
  int nextYear = date.year;
  if (nextMonth > 12) {
    nextMonth = 1;
    nextYear += 1;
  }
  return DateTime(nextYear, nextMonth, 1);
}