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

  // 💡 Метод для определения цвета процента
  Color _getPercentColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем процент для отображения, если null, используем 0.0
    final double displayPercent = attendancePercentage ?? 0.0;
    
    // 🧮 Расчет процентов посещаемости
    final int totalMarked = presentCount + absentCount + sickCount + ithubCount;
    // Предотвращаем деление на ноль: если отметок нет, используем 1.0 (чтобы проценты были 0.0)
    final double totalMarkedDouble = totalMarked == 0 ? 1.0 : totalMarked.toDouble(); 

    final double presentPercent = (presentCount / totalMarkedDouble) * 100;
    final double absentPercent = (absentCount / totalMarkedDouble) * 100;
    final double sickPercent = (sickCount / totalMarkedDouble) * 100;
    final double ithubPercent = (ithubCount / totalMarkedDouble) * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        final double titleFontSize = (cardWidth * 0.055).clamp(13, 20); // Было 14
      final double subtitleFontSize = (cardWidth * 0.04).clamp(11, 16); // Было 12
      final double labelFontSize = (cardWidth * 0.035).clamp(9, 14); // Было 10
      final double countFontSize = (cardWidth * 0.045).clamp(11, 18); // Было 12
      final double percentFontSize = (cardWidth * 0.05).clamp(13, 20); // Было 14

     
          return InkWell(
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
                  // 🟦 Шапка (без изменений)
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
                        Expanded( 
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
                  // 📊 Статистика (с процентами)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      children: [
                        _buildStatsRow([
                          // Передаем рассчитанные проценты
                          _buildStatusText("Присутствующие", presentCount, Colors.green, labelFontSize, countFontSize, presentPercent),
                          _buildStatusText("Отсутствующие", absentCount, Colors.red, labelFontSize, countFontSize, absentPercent),
                        ]),
                        const SizedBox(height: 6),
                        _buildStatsRow([
                          _buildStatusText("Больничный", sickCount, Colors.orange, labelFontSize, countFontSize, sickPercent),
                          _buildStatusText("IT-hub", ithubCount, Colors.purple, labelFontSize, countFontSize, ithubPercent),
                        ]),
                        const SizedBox(height: 6),
                        // Отметки / Не отмечено - оставим только количество, так как это другие метрики (студенты)
                        _buildStatsRow([
                          _buildStatusText("Отмечено", markedCount, Colors.blue, labelFontSize, countFontSize, -1), // -1 как флаг, что процент не нужен
                          _buildStatusText("Не отмечено", studentCount - markedCount, Colors.grey, labelFontSize, countFontSize, -1), // -1 как флаг, что процент не нужен
                        ]),
                        const SizedBox(height: 10), // Отступ перед процентом
                      ],
                    ),
                  ),
                  // 🎯 Средний процент посещаемости (ВНИЗУ) - без изменений
                  Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Средний \% посещаемости:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          // Отображаем процент за ВЕСЬ диапазон
                          '${displayPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: percentFontSize,
                            fontWeight: FontWeight.w900,
                            color: _getPercentColor(displayPercent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  // 📝 Обновленный метод для отображения процента
  Widget _buildStatusText(
    String label,
    int count,
    Color color,
    double labelFontSize,
    double countFontSize,
    double percentage, // Новый параметр
  ) {
    // Проверяем, нужно ли отображать процент (используем -1 как флаг, что не нужно)
    final bool showPercentage = percentage >= 0;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: countFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            // Отображаем процент только если он нужен
            if (showPercentage) ...[
              const SizedBox(width: 6),
              Text(
                '(${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}