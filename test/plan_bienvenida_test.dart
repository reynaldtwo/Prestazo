// ignore_for_file: avoid_print // Tests use print for detailed financial report output
/// Test: Generación de Ciclos Plan Bienvenida
///
/// Validar cómo quedarían los 13 ciclos semanales
/// para el plan con cuotas niveladas.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generación de 13 ciclos semanales - Plan Bienvenida', () {
    // =====================================================
    // DATOS DEL PRÉSTAMO
    // =====================================================
    const capital = 10000.0;
    const tasaMensual = 13.33;
    const plazoMeses = 3;
    const numeroCuotas = 13;
    const frecuenciaDias = 7; // Semanal
    final fechaDesembolso = DateTime(2025, 10);

    // =====================================================
    // CÁLCULOS
    // =====================================================
    const interesTotal = capital * (tasaMensual / 100) * plazoMeses;
    const totalAPagar = capital + interesTotal;
    const cuotaNivelada = totalAPagar / numeroCuotas;
    const principalPorCuota = capital / numeroCuotas;
    const interesPorCuota = cuotaNivelada - principalPorCuota;

    print('');
    print(
      '═══════════════════════════════════════════════════════════════════',
    );
    print(' PLAN BIENVENIDA - GENERACIÓN DE CICLOS');
    print(
      '═══════════════════════════════════════════════════════════════════',
    );
    print('');
    print(' DATOS DE ENTRADA:');
    print(' ─────────────────────────────────────────────────────────────────');
    print(' Capital:           ${capital.toStringAsFixed(2)} NIO');
    print(' Tasa Mensual:      $tasaMensual%');
    print(' Plazo:             $plazoMeses meses');
    print(' Frecuencia:        Semanal ($frecuenciaDias días)');
    print(' Total Cuotas:      $numeroCuotas');
    print(' Fecha Desembolso:  ${_formatDate(fechaDesembolso)}');
    print('');
    print(' CÁLCULOS:');
    print(' ─────────────────────────────────────────────────────────────────');
    print(' Interés Total:     ${interesTotal.toStringAsFixed(2)} NIO');
    print(' Total a Pagar:     ${totalAPagar.toStringAsFixed(2)} NIO');
    print(' Cuota Nivelada:    ${cuotaNivelada.toStringAsFixed(4)} NIO');
    print(' Principal/Cuota:   ${principalPorCuota.toStringAsFixed(4)} NIO');
    print(' Interés/Cuota:     ${interesPorCuota.toStringAsFixed(4)} NIO');
    print('');
    print(' CICLOS GENERADOS:');
    print(
      ' ═══════════════════════════════════════════════════════════════════',
    );
    print(
      ' #   │ Inicio       │ Fin          │ Vencimiento  │ Cuota      │ Principal  │ Interés',
    );
    print(
      ' ────┼──────────────┼──────────────┼──────────────┼────────────┼────────────┼──────────',
    );

    var startDate = fechaDesembolso;
    var sumaCuotas = 0.0;
    var sumaPrincipal = 0.0;
    var sumaInteres = 0.0;

    for (var i = 1; i <= numeroCuotas; i++) {
      final endDate = startDate.add(const Duration(days: frecuenciaDias - 1));
      final dueDate = startDate.add(const Duration(days: frecuenciaDias));

      // Ajustar última cuota para cerrar exacto
      double cuota;
      double principal;
      double interes;

      if (i == numeroCuotas) {
        // Última cuota absorbe el redondeo
        cuota = totalAPagar - sumaCuotas;
        principal = capital - sumaPrincipal;
        interes = interesTotal - sumaInteres;
      } else {
        cuota = double.parse(cuotaNivelada.toStringAsFixed(2));
        principal = double.parse(principalPorCuota.toStringAsFixed(2));
        interes = double.parse(interesPorCuota.toStringAsFixed(2));
      }

      sumaCuotas += cuota;
      sumaPrincipal += principal;
      sumaInteres += interes;

      print(
        ' ${i.toString().padLeft(2)} │ ${_formatDate(startDate)} │ ${_formatDate(endDate)} │ ${_formatDate(dueDate)} │ ${cuota.toStringAsFixed(2).padLeft(10)} │ ${principal.toStringAsFixed(2).padLeft(10)} │ ${interes.toStringAsFixed(2).padLeft(8)}',
      );

      startDate = dueDate;
    }

    print(
      ' ────┼──────────────┼──────────────┼──────────────┼────────────┼────────────┼──────────',
    );
    print(
      ' TOTAL                                               │ ${sumaCuotas.toStringAsFixed(2).padLeft(10)} │ ${sumaPrincipal.toStringAsFixed(2).padLeft(10)} │ ${sumaInteres.toStringAsFixed(2).padLeft(8)}',
    );
    print(
      ' ═══════════════════════════════════════════════════════════════════',
    );
    print('');

    // Verificaciones
    expect(sumaCuotas, closeTo(totalAPagar, 0.01));
    expect(sumaPrincipal, closeTo(capital, 0.01));
    expect(sumaInteres, closeTo(interesTotal, 0.01));
  });
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
