import 'package:flutter/material.dart';

class AttendanceTile extends StatelessWidget {
  final String name;
  final int index;
  final String status;
  final Function(String) onStatusChange;

  const AttendanceTile({
    super.key,
    required this.name,
    required this.index,
    required this.status,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    _statusButton('present', 'Присутствует', Colors.green),
                    _statusButton('absent', 'Отсутствует', Colors.red),
                    _statusButton('sick', 'Больничный', Colors.orange),
                    _statusButton('ithub', 'IT-hub', Colors.purple),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String value, String label, Color color) {
    final isSelected = status == value;
    return GestureDetector(
      onTap: () => onStatusChange(value),
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