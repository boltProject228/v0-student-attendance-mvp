import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/academic_range.dart';
import '../logic/date_ranges.dart';

class DateFilterBar extends StatelessWidget {
  final bool isMobile;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRange;
  final List<AcademicRange> fixedRanges;
  final Function(AcademicRange?) onFixedRangeSelected;
  final Function(DateTime, DateTime?) onManualRangeSelected;

  const DateFilterBar({
    super.key,
    required this.isMobile,
    required this.startDate,
    required this.endDate,
    required this.isRange,
    required this.fixedRanges,
    required this.onFixedRangeSelected,
    required this.onManualRangeSelected,
  });

  String _getDateLabel() {
    if (isRange) {
      return '${startDate != null ? DateFormat('dd.MM.yyyy').format(startDate!) : 'Выбрать'} - '
          '${endDate != null ? DateFormat('dd.MM.yyyy').format(endDate!) : 'Выбрать'}';
    }
    return startDate != null ? DateFormat('dd.MM.yyyy').format(startDate!) : 'Выбрать дату';
  }

  String? _getCurrentPresetLabel() {
    if (startDate == null) return null;
    final found = fixedRanges.firstWhere(
      (r) =>
          r.startDate.year == startDate!.year &&
          r.startDate.month == startDate!.month &&
          r.startDate.day == startDate!.day &&
          ((isRange &&
                  r.endDate != null &&
                  r.endDate!.year == endDate!.year &&
                  r.endDate!.month == endDate!.month &&
                  r.endDate!.day == endDate!.day) ||
              (!isRange && r.endDate == null)),
      orElse: () => AcademicRange(label: '', startDate: DateTime.now()),
    );
    return found.label.isNotEmpty ? found.label : null;
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = _getDateLabel();
    final String? currentPresetLabel = _getCurrentPresetLabel();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.calendar_today, size: isMobile ? 16 : 20),
              label: Text(
                currentPresetLabel ?? dateLabel,
                style: TextStyle(fontSize: isMobile ? 14 : 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 12),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  locale: const Locale('ru', 'RU'),
                );
                if (pickedRange != null) {
                  final isSingleDay = pickedRange.start.isAtSameMomentAs(pickedRange.end);
                  onManualRangeSelected(pickedRange.start, isSingleDay ? null : pickedRange.end);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AcademicRange>(
            icon: Icon(Icons.filter_list, size: isMobile ? 20 : 24),
            onSelected: onFixedRangeSelected,
            itemBuilder: (BuildContext context) {
              return fixedRanges.map((AcademicRange range) {
                return PopupMenuItem<AcademicRange>(
                  value: range,
                  child: Text(range.label),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}