import 'package:attendance_system/models/group.dart';
import 'package:flutter/material.dart';

class StudentGroupChips extends StatelessWidget {
  final List<Group> groups;
  final String selectedGroupChip;
  final bool isMobile;
  final ValueChanged<String> onGroupSelected;

  const StudentGroupChips({
    super.key,
    required this.groups,
    required this.selectedGroupChip,
    required this.isMobile,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Все группы',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: groups.map((group) {
                final isSelected = selectedGroupChip == group.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        group.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    backgroundColor: isSelected ? Colors.blue : Colors.blue.shade100,
                    onPressed: () {
                      onGroupSelected(isSelected ? '' : group.id);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}