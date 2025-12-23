/// Validation utilities for forms
class Validators {
  Validators._();

  /// Validate required field
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Validate money amount
  static String? money(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese un monto';
    }
    
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Monto inválido';
    }
    
    if (amount <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    
    if (min != null && amount < min) {
      return 'El monto mínimo es $min';
    }
    
    if (max != null && amount > max) {
      return 'El monto máximo es $max';
    }
    
    return null;
  }

  /// Validate interest rate (as decimal, e.g., 0.20 for 20%)
  static String? interestRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese la tasa de interés';
    }
    
    final rate = double.tryParse(value.replaceAll(',', '.'));
    if (rate == null) {
      return 'Tasa inválida';
    }
    
    // Accept values like 20 (percent) or 0.20 (decimal)
    final normalizedRate = rate > 1 ? rate / 100 : rate;
    
    if (normalizedRate <= 0) {
      return 'La tasa debe ser mayor a 0';
    }
    
    if (normalizedRate > 1) {
      return 'La tasa no puede ser mayor a 100%';
    }
    
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 8) {
      return 'Número de teléfono inválido';
    }
    
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese el nombre';
    }
    
    if (value.trim().length < 2) {
      return 'El nombre es muy corto';
    }
    
    return null;
  }

  /// Validate date is not in the future
  static String? dateNotFuture(DateTime? date) {
    if (date == null) {
      return 'Seleccione una fecha';
    }
    
    if (date.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    
    return null;
  }

  /// Validate day of month (1-31)
  static String? dayOfMonth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final day = int.tryParse(value);
    if (day == null || day < 1 || day > 31) {
      return 'Día inválido (1-31)';
    }
    
    return null;
  }

  /// Combine multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }
}
