import 'package:flutter/material.dart';

class AnalyticsTabBar extends StatelessWidget {
  final TabController tabController;
  final bool isMobile;

  const AnalyticsTabBar({
    super.key,
    required this.tabController,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final double tabFontSize = isMobile ? 12.0 : 20.0;

    return TabBar(
      controller: tabController,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: tabFontSize),
      tabs: const [
        Tab(text: 'Аналитика по группам'),
        Tab(text: 'Аналитика по студентам'),
      ],
    );
  }
}