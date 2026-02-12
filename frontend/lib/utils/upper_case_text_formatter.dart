import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 🔑 Ключевой метод: преобразует новый текст в ВЕРХНИЙ РЕГИСТР (КАПС)
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      // Сохраняем позицию курсора, чтобы ввод был удобным
      selection: newValue.selection,
    );
  }
}