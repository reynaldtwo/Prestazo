import 'package:flutter_test/flutter_test.dart';
import 'package:prestamos_app/core/utils/string_utils.dart';

/// Unit tests for string utilities
void main() {
  group('incrementStringCode', () {
    test('should increment simple numbers', () {
      expect(incrementStringCode('1'), '2');
      expect(incrementStringCode('10'), '11');
      expect(incrementStringCode('99'), '100');
      expect(incrementStringCode('100'), '101');
    });

    test('should handle empty string', () {
      expect(incrementStringCode(''), '1');
    });

    test('should increment prefixed numbers', () {
      expect(incrementStringCode('A-001'), 'A-002');
      expect(incrementStringCode('INV-99'), 'INV-100');
      expect(incrementStringCode('LOAN-'), 'LOAN-1');
    });

    test('should preserve leading zeros when possible', () {
      expect(incrementStringCode('001'), '002');
      expect(incrementStringCode('009'), '010');
      expect(incrementStringCode('099'), '100'); // Overflow, can't preserve
    });

    test('should append 1 to text without numbers', () {
      expect(incrementStringCode('ABC'), 'ABC1');
      expect(incrementStringCode('TEST'), 'TEST1');
    });

    test('should handle complex prefixes', () {
      expect(incrementStringCode('PREST-2025-001'), 'PREST-2025-002');
      expect(incrementStringCode('REC#50'), 'REC#51');
    });
  });
}
