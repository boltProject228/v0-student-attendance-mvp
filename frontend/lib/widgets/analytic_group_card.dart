import 'package:flutter/material.dart';
import '../models/group.dart';

class AnalyticGroupCard extends StatelessWidget {
  final Group group;
  final int studentCount;
  final int presentCount;
  final int absentCount;
  final int sickCount;
  final int ithubCount;
  final int markedCount;
  final double? attendancePercentage; // Nullable
  final VoidCallback onTap;

  const AnalyticGroupCard({
    super.key,
    required this.group,
    required this.studentCount,
    required this.presentCount,
    required this.absentCount,
    required this.sickCount,
    required this.ithubCount,
    required this.markedCount,
    this.attendancePercentage, // Nullable
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const cardHeight = 200.0;

        // 📏 Адаптивные размеры шрифтов
        final double titleFontSize = (cardWidth * 0.055).clamp(14, 20);
        final double subtitleFontSize = (cardWidth * 0.04).clamp(12, 16);
        final double labelFontSize = (cardWidth * 0.035).clamp(10, 14);
        final double countFontSize = (cardWidth * 0.045).clamp(12, 18);

        return SizedBox(
          height: cardHeight,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🟦 Шапка
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade500],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded( // 💡 ИСПРАВЛЕНО: Заменен Flexible на Expanded для избежания RenderFlex overflow
                          child: Text(
                            'Группа ${group.name}',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              '$studentCount студентов',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 📊 Статистика
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatsRow([
                            _buildStatusText("Присутствующие", presentCount, Colors.green, labelFontSize, countFontSize),
                            _buildStatusText("Отсутствующие", absentCount, Colors.red, labelFontSize, countFontSize),
                          ]),
                          _buildStatsRow([
                            _buildStatusText("Больничный", sickCount, Colors.orange, labelFontSize, countFontSize),
                            _buildStatusText("IT-hub", ithubCount, Colors.purple, labelFontSize, countFontSize),
                          ]),
                          _buildStatsRow([
                            _buildStatusText("Отмечено", markedCount, Colors.blue, labelFontSize, countFontSize),
                            _buildStatusText("Не отмечено", studentCount - markedCount, Colors.grey, labelFontSize, countFontSize),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(List<Widget> children) {
    return Row(
      children: children
          .map(
            (w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatusText(
    String label,
    int count,
    Color color,
    double labelFontSize,
    double countFontSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: countFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}