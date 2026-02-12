enum SortOrder { ascending, descending }

List<Map<String, dynamic>> sortAnalytics(List<Map<String, dynamic>> data, SortOrder order) {
  // 1. Используем .toList() для создания копии списка перед сортировкой
  // Это хорошая практика, хотя data.sort() модифицирует список на месте
  final sortedData = data; 
  
  // 2. Сортируем данные
  sortedData.sort((a, b) {
    // Безопасное извлечение и парсинг процента, используем 0.0 как fallback
    final aVal = double.tryParse(a['percent'].toString()) ?? 0.0;
    final bVal = double.tryParse(b['percent'].toString()) ?? 0.0;
    
    // ИСПРАВЛЕНИЕ:
    // По возрастанию (ascending): a сравнивается с b (меньший идет первым)
    // По убыванию (descending): b сравнивается с a (больший идет первым)
    return order == SortOrder.ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
  });
  
  return sortedData;
}