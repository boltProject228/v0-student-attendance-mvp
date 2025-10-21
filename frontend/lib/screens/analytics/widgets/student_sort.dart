import 'package:flutter/material.dart';
import '../logic/sorting.dart';

class StudentSort extends StatelessWidget {
  final SortOrder studentSortOrder;
  final bool isMobile;
  final Function(SortOrder) onSortChanged;

  const StudentSort({
    super.key,
    required this.studentSortOrder,
    required this.isMobile,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ascActive = studentSortOrder == SortOrder.ascending;
    final ascColor = ascActive ? Colors.blue : Colors.grey.shade600;
    final descActive = studentSortOrder == SortOrder.descending;
    final descColor = descActive ? Colors.blue : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сортировка по % посещаемости',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          studentSortOrder == SortOrder.ascending
              ? 'Сейчас выбрано: по возрастанию'
              : 'Сейчас выбрано: по убыванию',
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              icon: Icon(
                Icons.arrow_upward,
                color: ascColor,
                size: isMobile ? 22 : 28,
              ),
              label: Text(
                'По возрастанию',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: ascColor,
                ),
              ),
              onPressed: () => onSortChanged(SortOrder.ascending),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            TextButton.icon(
              icon: Icon(
                Icons.arrow_downward,
                color: descColor,
                size: isMobile ? 22 : 28,
              ),
              label: Text(
                'По убыванию',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: descColor,
                ),
              ),
              onPressed: () => onSortChanged(SortOrder.descending),
            ),
          ],
        ),
      ],
    );
  }
}