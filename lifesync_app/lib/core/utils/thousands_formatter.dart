import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int value = int.parse(cleanText);
    String formattedText = _formatter.format(value);

    int cursorOffset = newValue.selection.end + (formattedText.length - newValue.text.length);
    cursorOffset = cursorOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}