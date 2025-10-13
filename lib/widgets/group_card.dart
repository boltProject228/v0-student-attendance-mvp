import 'package:flutter/material.dart';
import '../models/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final int studentCount;
  final int presentCount;
  final int absentCount;
  final int sickCount;
  final int wskCount;
  final int markedCount;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.studentCount,
    required this.presentCount,
    required this.absentCount,
    required this.sickCount,
    required this.wskCount,
    required this.markedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double titleFontSize = isMobile ? 16 : 18;
    final double subtitleFontSize = isMobile ? 12 : 14;
    final double countFontSize = isMobile ? 14 : 16;
    final double labelFontSize = isMobile ? 11 : 13;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
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
                  // 🟦 Шапка карточки (Название и общее количество)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
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
                            const Icon(
                              Icons.people_alt_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Всего в группе: $studentCount студентов',
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

                  // 📊 Первая строка статистики
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatusText(
                            "Присутствующие",
                            presentCount,
                            Colors.green,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                        Expanded(
                          child: _buildStatusText(
                            "Отсутствующие",
                            absentCount,
                            Colors.red,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📊 Вторая строка статистики
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatusText(
                            "Больничный",
                            sickCount,
                            Colors.orange,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                        Expanded(
                          child: _buildStatusText(
                            "WSK",
                            wskCount,
                            Colors.purple,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📊 Третья строка статистики
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatusText(
                            "Отмечено",
                            markedCount,
                            Colors.blue,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                        Expanded(
                          child: _buildStatusText(
                            "Не отмечено",
                            studentCount - markedCount,
                            Colors.grey,
                            labelFontSize,
                            countFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
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