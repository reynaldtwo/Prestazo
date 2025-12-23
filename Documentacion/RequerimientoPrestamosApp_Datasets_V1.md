# Datasets y Escenarios de Prueba V1 – PrestamosApp (para validar cálculos y flujos)

## 0) Objetivo
Estos escenarios se usan para validar que la app (y la BD) producen resultados correctos en:
- Generación de ciclos
- Cálculo de interés
- Aplicación de pagos
- Mora
- Capitalización ON/OFF
- Anulación de pagos

---

## Escenario 1: Cliente quincenal – paga solo interés puntual
**Cliente:** Juan (BIWEEKLY)  
**Préstamo:** 5,000 NIO, tasa mensual 0.20 (20%), desembolso 2025-12-01  
**Interés quincenal esperado:** 5,000 * (0.20/2) = 500.00

**Ciclos esperados:**
- C1 Due 2025-12-15 InterestExpected 500
- C2 Due 2025-12-30 InterestExpected 500
- C3 Due 2026-01-14 InterestExpected 500

**Pagos:**
- 2025-12-15 paga 500 (solo interés) → C1 pendiente 0
- 2025-12-30 paga 500 (solo interés) → C2 pendiente 0

**Resultado esperado:**
- CapitalBalance = 5,000
- Interés cobrado mes dic 2025 = 1,000
- No mora

---

## Escenario 2: Cliente mensual – paga interés al final y abona capital irregular
**Cliente:** María (MONTHLY)  
**Préstamo:** 10,000 NIO, tasa 0.10, desembolso 2025-12-10  
**Interés mensual esperado:** 10,000 * 0.10 = 1,000.00

**Ciclos:**
- C1 Due 2026-01-10 InterestExpected 1,000

**Pagos:**
- 2026-01-10 paga 1,500 mixto:
  - 1,000 a interés C1
  - 500 a capital

**Resultado esperado:**
- CapitalBalance = 9,500
- Próximo ciclo (si se genera) debe calcular interés sobre 9,500 (950.00 mensual)

---

## Escenario 3: Atraso con mora
**Cliente:** Pedro (MONTHLY)  
**Préstamo:** 8,000 NIO, tasa 0.20, desembolso 2025-11-01  
**MoraDays:** 7

**Ciclos:**
- C1 Due 2025-12-01 InterestExpected 1,600
- C2 Due 2026-01-01 InterestExpected (según saldo)

**Pagos:**
- Ninguno hasta 2025-12-10

**Resultado esperado al 2025-12-10:**
- C1 InterestPending = 1,600
- Préstamo IN_MORA (porque DueDate 2025-12-01 < 2025-12-03 con mora 7 días)
- Cliente aparece en “Atrasados”

---

## Escenario 4: Capitalización ON
**Settings:** CapitalizeUnpaidInterest = 1  
**Cliente:** Ana (MONTHLY)  
**Préstamo:** 5,000 NIO, tasa 0.20, desembolso 2025-11-15  
**Ciclo C1 Due:** 2025-12-15 InterestExpected 1,000

**Pagos:**
- Ninguno hasta después del vencimiento + job capitalización

**Resultado esperado tras capitalización:**
- CapitalBalance pasa de 5,000 a 6,000
- C1 InterestPending = 0, Status=CLOSED, IsCapitalized=1, CapitalizedAmount=1,000
- Próximo ciclo InterestExpected se calcula sobre 6,000 → 1,200 mensual

---

## Escenario 5: Anulación de pago
Usar Escenario 2.  
Anular el pago del 2026-01-10.

**Resultado esperado:**
- Payment status = VOIDED con motivo
- Se recalculan:
  - C1 InterestPaid vuelve a 0, InterestPending vuelve a 1,000
  - CapitalBalance vuelve a 10,000
- AuditLog registra anulación
