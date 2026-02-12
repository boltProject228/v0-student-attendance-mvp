import 'package:flutter/material.dart';
import '../models/group.dart';

class AnalyticGroupCard extends StatelessWidget {
  final Group group;
  final int studentCount;
  final int presentCount;
  final int absentCount;
  final int sickCount;
  final int ithubCount;
  final int markedCount; // Входящее значение может быть неверным, поэтому пересчитаем
  final double? attendancePercentage;
  final VoidCallback onTap;
  final bool isRangeSelected;

  const AnalyticGroupCard({
    super.key,
    required this.group,
    required this.studentCount,
    required this.presentCount,
    required this.absentCount,
    required this.sickCount,
    required this.ithubCount,
    required this.markedCount,
    this.attendancePercentage,
    required this.onTap,
    required this.isRangeSelected,
  });

  Color _getPercentColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final double displayPercent = attendancePercentage ?? 0.0;
    // showCounts будет true, если выбран один день (!isRangeSelected)
    final bool showCounts = !isRangeSelected;

    // --- ЛОГИКА РАСЧЕТА ПРОЦЕНТОВ ---
    final int totalMarkedForPercent = presentCount + absentCount + ithubCount;
    final double totalMarkedDoubleForPercent = totalMarkedForPercent == 0 ? 1.0 : totalMarkedForPercent.toDouble();

    final double presentPercent = ((presentCount + ithubCount) / totalMarkedDoubleForPercent) * 100;
    final double absentPercent = (absentCount / totalMarkedDoubleForPercent) * 100;

    final double sickTotal = (totalMarkedForPercent + sickCount).toDouble();
    final double sickPercent = sickTotal == 0 ? 0.0 : (sickCount / sickTotal) * 100;

    final double ithubPercent = (ithubCount / totalMarkedDoubleForPercent) * 100;
    // ------------------------------------
    
    // 💡 ЛОГИКА ОГРАНИЧЕНИЯ: Ограничиваем общее количество отмеченных студентов (сумма уникальных статусов)
    // значением studentCount только в режиме "Сегодня" (showCounts = true).
    int markedStudentsTotal = presentCount + absentCount + sickCount + ithubCount;
    
    final int actualMarkedCount = showCounts 
        ? markedStudentsTotal.clamp(0, studentCount) // Ограничиваем сверху studentCount (для 1 дня)
        : markedStudentsTotal; // В режиме диапазона - это общая сумма всех отметок (слоты)

    // Расчет не отмеченных студентов, используя скорректированный actualMarkedCount.
    // При isRangeSelected=true, actualMarkedCount будет большим числом, и unmarkedCount будет 0.
    final int unmarkedCount = (studentCount - actualMarkedCount).clamp(0, studentCount);
    
    // Используйте высоту, которая у вас задана в mainAxisExtent (например, 303.0)
    const cardDesiredHeight = 303.0; 

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        // 📏 Адаптивные размеры шрифтов
        final double titleFontSize = (cardWidth * 0.055).clamp(14, 20);
        final double subtitleFontSize = (cardWidth * 0.04).clamp(11, 16);
        final double labelFontSize = (cardWidth * 0.035).clamp(9, 14);
        final double mainValueFontSize = (cardWidth * 0.06).clamp(16, 24); 
        final double percentFontSize = (cardWidth * 0.05).clamp(13, 20);
        
        return SizedBox( 
          height: cardDesiredHeight,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade500],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              // Student count всегда статичен и равен studentCount
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
                  
                  // 📊 Statistics
                  Expanded( 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsRow([
                            // В режиме "Сегодня" показываем только presentCount. Для диапазона - сумма.
                            _buildStatusText(
                              "Присутствовали", 
                              showCounts ? presentCount : presentCount + ithubCount, 
                              Colors.green, labelFontSize, mainValueFontSize, 
                              presentPercent, 
                              showCounts
                            ),
                            _buildStatusText("Отсутствующие", absentCount, Colors.red, labelFontSize, mainValueFontSize, absentPercent, showCounts),
                          ]),
                          _buildStatsRow([
                            // Больничный. Счетчик скрыт в режиме диапазона.
                            _buildStatusText("Больничный", sickCount, Colors.orange, labelFontSize, mainValueFontSize, sickPercent, showCounts),
                            // IT-hub. Счетчик скрыт в режиме диапазона.
                            _buildStatusText("IT-hub (отдельно)", ithubCount, Colors.purple, labelFontSize, mainValueFontSize, ithubPercent, showCounts),
                          ]),
                          
                          // ❗ ИСПРАВЛЕНИЕ: Этот ряд всегда отображается (без if (showCounts))
                          _buildStatsRow([
                            // showCount = true, чтобы счетчик всегда отображался
                            _buildStatusText("Отмечено", actualMarkedCount, Colors.blue, labelFontSize, mainValueFontSize, -1, true),
                            // showCount = true, чтобы счетчик всегда отображался
                            _buildStatusText("Не отмечено", unmarkedCount, Colors.grey, labelFontSize, mainValueFontSize, -1, true),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  
                  // 🎯 Footer Content
                  Container(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8), 
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Средний % посещаемости:',
                          style: TextStyle(
                            fontSize: labelFontSize + 1,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
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
    double mainValueFontSize,
    double percentage,
    bool showCount,
  ) {
    final bool showPercentage = percentage >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
            if (showCount)
              Text(
                '$count',
                style: TextStyle(
                  fontSize: mainValueFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            
            if (showPercentage)
              Padding(
                // Логика отображения процентов: если счетчик показан, то процент в скобках и меньше, иначе - крупно.
                padding: EdgeInsets.only(left: showCount ? 6 : 0), 
                child: Text(
                  showCount
                      ? '(${percentage.toStringAsFixed(1)}%)'
                      : '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: showCount ? labelFontSize : mainValueFontSize, 
                    fontWeight: showCount ? FontWeight.w500 : FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}