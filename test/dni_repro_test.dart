import 'package:flutter_test/flutter_test.dart';

void main() {
  String? validateDni(
    String? value, {
    required String? dniMask,
    required bool validateDniFormat,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es requerido';
    }

    if (validateDniFormat && dniMask != null && dniMask.isNotEmpty) {
      final mask = dniMask;
      final input = value.trim();

      // Mask length check
      if (input.length != mask.length) {
        return 'El formato debe ser: $mask (Length mismatch ${input.length} != ${mask.length})';
      }

      // Character check
      for (var i = 0; i < mask.length; i++) {
        final maskChar = mask[i];
        final inputChar = input[i];

        if (maskChar == '#') {
          if (!RegExp(r'\d').hasMatch(inputChar)) {
            return 'Posición ${i + 1} debe ser un dígito';
          }
        } else if (maskChar == '@') {
          if (!RegExp('[a-zA-Z]').hasMatch(inputChar)) {
            return 'Posición ${i + 1} debe ser una letra';
          }
        } else if (maskChar == '*') {
          // Any char allowed
        } else {
          // Separator
          if (inputChar != maskChar) {
            return 'Falta el separador "$maskChar" en posición ${i + 1}';
          }
        }
      }
    }
    return null;
  }

  test('DNI Validation Logic Test', () {
    const mask = '###-######-####@';

    // Valid case
    expect(
      validateDni('123-123456-1234A', dniMask: mask, validateDniFormat: true),
      null,
      reason: 'Should match valid input',
    );

    // Invalid length
    expect(
      validateDni('123', dniMask: mask, validateDniFormat: true),
      isNotNull,
      reason: 'Should fail length check',
    );

    // Invalid format (letter where number expected)
    expect(
      validateDni('A23-123456-1234A', dniMask: mask, validateDniFormat: true),
      isNotNull,
      reason: 'Should fail digit check',
    );

    // Invalid format (separator missing)
    expect(
      validateDni('1230123456-1234A', dniMask: mask, validateDniFormat: true),
      isNotNull,
      reason: 'Should fail separator check',
    );

    // Mismatch mask
    expect(
      validateDni('123-123456-12345', dniMask: mask, validateDniFormat: true),
      isNotNull,
      reason: 'Last char should be letter',
    );
  });
}
