import 'package:flutter/material.dart';

class AttendanceTile extends StatelessWidget {
  final String name;
  final String status;
  final Function(String) onStatusChange;

  const AttendanceTile({
    super.key,
    required this.name,
    required this.status,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 👤 Имя студента
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 🟡 Статусы — понятные слова
            Row(
              children: [
                _statusButton('present', 'Присутствует', Colors.green),
                const SizedBox(width: 6),
                _statusButton('absent', 'Отсутствует', Colors.red),
                const SizedBox(width: 6),
                _statusButton('sick', 'Больничный', Colors.orange),
                const SizedBox(width: 6),
                _statusButton('wsk', 'WSK', Colors.purple),
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
