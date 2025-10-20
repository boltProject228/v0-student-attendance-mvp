import 'package:flutter/material.dart';

class AnalyticsAttendanceTile extends StatelessWidget {
  final String name;
  final int index;
  final String status; // Current day's status
  final double attendancePercentage; // Overall % for period
  final List<String> statusSequence; // Sequence of statuses (e.g., ['present', 'ithub', 'absent'])
  final Function(String)? onStatusChange; // Nullable for read-only

  const AnalyticsAttendanceTile({
    super.key,
    required this.name,
    required this.index,
    required this.status,
    required this.attendancePercentage,
    required this.statusSequence,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final percentageColor = attendancePercentage > 80
        ? Colors.green
        : attendancePercentage >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '$index.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${attendancePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: percentageColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (onStatusChange != null) // Show buttons only if editable
              Wrap(
                spacing: 6,
                children: [
                  _statusButton('present', 'Присутствует', Colors.green),
                  _statusButton('absent', 'Отсутствует', Colors.red),
                  _statusButton('sick', 'Больничный', Colors.orange),
                  _statusButton('ithub', 'IT-hub', Colors.purple),
                ],
              ),
            const SizedBox(height: 8),
            // --- ИЗМЕНЕНИЕ: Добавлены Tooltip к чипам последовательности ---
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: statusSequence.asMap().entries.map((entry) { // Используем asMap().entries для получения индекса
                final index = entry.key;
                final s = entry.value;

                final color = s == 'present' || s == 'ithub'
                    ? Colors.green
                    : s == 'absent'
                        ? Colors.red
                        : s == 'sick'
                            ? Colors.orange
                            : Colors.grey;
                final label = s == 'present'
                    ? 'П'
                    : s == 'ithub'
                        ? 'IT'
                        : s == 'absent'
                            ? 'О'
                            : s == 'sick'
                                ? 'Б'
                                : 'Н';

                return Tooltip(
                  message: 'Статус за период ${index + 1}: $s', // Tooltip с номером периода
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // -----------------------------------------------------------------
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String value, String label, Color color) {
    final isSelected = status == value;
    return GestureDetector(
      onTap: onStatusChange != null ? () => onStatusChange!(value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}