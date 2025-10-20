import 'package:flutter/material.dart';

class AttendanceTile extends StatelessWidget {
  final String name;
  final int index;
  final String status;
  final Function(String) onStatusChange;
  final bool isMobile;
  // NOTE: Для полноценного редактирования истории, сюда должна передаваться дата,
  // которую редактируем, но для текущей задачи используем DateTime.now()

  const AttendanceTile({
    super.key,
    required this.name,
    required this.index,
    required this.status,
    required this.onStatusChange,
    this.isMobile = false,
  });

  // --- КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ: ПРОВЕРКА ДНЯ НЕДЕЛИ ---
  bool _isWeekday(DateTime date) {
    final dayOfWeek = date.weekday;
    // Monday (1) through Friday (5)
    return dayOfWeek >= DateTime.monday && dayOfWeek <= DateTime.friday;
  }
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0, vertical: isMobile ? 10.0 : 14.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '$index.',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      _statusButton('present', 'Присутствует', Colors.green),
                      _statusButton('absent', 'Отсутствует', Colors.red),
                      _statusButton('sick', 'Больничный', Colors.orange),
                      _statusButton('ithub', 'IT-hub', Colors.purple),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
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
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 6.0,
                    children: [
                      _statusButton('present', 'Присутствует', Colors.green),
                      _statusButton('absent', 'Отсутствует', Colors.red),
                      _statusButton('sick', 'Больничный', Colors.orange),
                      _statusButton('ithub', 'IT-hub', Colors.purple),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusButton(String value, String label, Color color) {
    final isSelected = status == value;
    final bool isEditable = _isWeekday(DateTime.now()); // Проверка текущего дня

    return GestureDetector(
      onTap: isEditable ? () => onStatusChange(value) : null, // Отключаем onTap, если не будний день
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 10.0, vertical: isMobile ? 4.0 : 6.0),
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
            // Цвет текста серый, если редактирование запрещено
            color: isEditable
                ? (isSelected ? Colors.white : Colors.black87)
                : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 11 : 12,
          ),
        ),
      ),
    );
  }
}