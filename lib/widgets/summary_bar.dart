import 'package:flutter/material.dart';

class SummaryBar extends StatelessWidget {
  final int present;
  final int absent;
  final int sick;
  final int wsk;
  final int unmarked;
  final VoidCallback onSave;

  const SummaryBar({
    super.key,
    required this.present,
    required this.absent,
    required this.sick,
    required this.wsk,
    required this.unmarked,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _chip(Colors.green, 'Присутствует $present'),
              _chip(Colors.red, 'Отсутствует $absent'),
              _chip(Colors.orange, 'Больничный $sick'),
              _chip(Colors.purple, 'WSK $wsk'),
              _chip(Colors.grey, 'Не отмечено $unmarked'),
            ],
          ),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _chip(Color color, String text) {
    return Chip(
      backgroundColor: color,
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}