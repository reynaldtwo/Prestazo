/// String utility functions for the application.
library;

/// Increment alphanumeric codes for sequential numbering
///
/// Examples:
/// - '10' -> '11'
/// - 'A-001' -> 'A-002'
/// - 'INV-99' -> 'INV-100'
/// - 'ABC' -> 'ABC1' (appends 1 if no number found)
String incrementStringCode(String code) {
  if (code.isEmpty) return '1';

  final regex = RegExp(r'(\d+)$');
  final match = regex.firstMatch(code);

  if (match != null) {
    final numberStr = match.group(1)!;
    final prefix = code.substring(0, code.length - numberStr.length);
    final number = int.parse(numberStr);
    final newNumber = number + 1;

    // Preserve padding if number length didn't increase
    var newNumberStr = newNumber.toString();
    if (newNumberStr.length < numberStr.length) {
      newNumberStr = newNumberStr.padLeft(numberStr.length, '0');
    }

    return '$prefix$newNumberStr';
  } else {
    // No number found, append 1
    return '${code}1';
  }
}
