import 'package:flutter/material.dart';

class SummaryBar extends StatelessWidget {
  final int present;
  final int absent;
  final int sick;
  final int ithub;
  final int unmarked;
  final VoidCallback onSave;
  final bool isMobile;

  const SummaryBar({
    super.key,
    required this.present,
    required this.absent,
    required this.sick,
    required this.ithub,
    required this.unmarked,
    required this.onSave,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0, vertical: isMobile ? 8.0 : 12.0),
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
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _chip(Colors.green, 'Присутствует $present', isMobile),
                      _chip(Colors.red, 'Отсутствует $absent', isMobile),
                      _chip(Colors.orange, 'Больничный $sick', isMobile),
                      _chip(Colors.purple, 'IT-hub $ithub', isMobile),
                      _chip(Colors.grey, 'Не отмечено $unmarked', isMobile),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 48), // Full width for easy tap
                    ),
                    child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _chip(Colors.green, 'Присутствует $present', isMobile),
                        _chip(Colors.red, 'Отсутствует $absent', isMobile),
                        _chip(Colors.orange, 'Больничный $sick', isMobile),
                        _chip(Colors.purple, 'IT-hub $ithub', isMobile),
                        _chip(Colors.grey, 'Не отмечено $unmarked', isMobile),
                      ],
                    ),
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
      ),
    );
  }

  Widget _chip(Color color, String text, bool isMobile) {
    return Chip(
      backgroundColor: color,
      labelPadding: EdgeInsets.symmetric(horizontal: isMobile ? 6.0 : 8.0),
      label: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }
}