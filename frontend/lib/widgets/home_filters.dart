import 'package:flutter/material.dart';

class HomeFilters extends StatelessWidget {
  final String searchQuery;
  final String selectedSpecialty;
  final String selectedCourse;
  final List<String> specialties;
  final List<String> availableCourses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<String> onCourseChanged;

  const HomeFilters({
    super.key,
    required this.searchQuery,
    required this.selectedSpecialty,
    required this.selectedCourse,
    required this.specialties,
    required this.availableCourses,
    required this.onSearchChanged,
    required this.onSpecialtyChanged,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Название группы',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Поиск по названию группы',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Специальность',
                  value: selectedSpecialty,
                  items: specialties,
                  onChanged: onSpecialtyChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Курс',
                  value: selectedCourse,
                  items: availableCourses,
                  onChanged: onCourseChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: const TextStyle(color: Colors.black),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
          items: items.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: Colors.black)))).toList(),
          onChanged: (val) => onChanged(val ?? value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
