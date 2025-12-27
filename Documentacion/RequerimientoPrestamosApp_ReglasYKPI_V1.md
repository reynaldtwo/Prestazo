# Reglas de Negocio Deterministas V1 (Calendario, Cálculos, KPIs) – PrestamosApp

## 1) Convenciones monetarias y redondeo
- Moneda principal: NIO.
- Todos los montos se redondean a **2 decimales** en cada operación que actualice saldos.
- Tasa mensual se almacena como **decimal** (ej. 0.20 = 20%).

---

## 2) Frecuencia por cliente
- Cada cliente tiene `BillingFrequency`:
  - `BIWEEKLY` (quincenal)
  - `MONTHLY` (mensual)
- La frecuencia del cliente se copia a los ciclos creados (`BillingCycle.Frequency`) para mantener histórico.

---

## 3) Regla de calendario para ciclos (sin ambigüedad)
### 3.1 Quincenal (BIWEEKLY) – regla V1
- Los ciclos son de **15 días** contados desde la **fecha de desembolso** del préstamo.
- Ejemplo: Desembolso 2025-12-01
  - Ciclo 1: 2025-12-01 a 2025-12-15 (DueDate 2025-12-15)
  - Ciclo 2: 2025-12-16 a 2025-12-30 (DueDate 2025-12-30)
  - Ciclo 3: 2025-12-31 a 2026-01-14 (DueDate 2026-01-14)

### 3.2 Mensual (MONTHLY) – regla V1
- El ciclo mensual vence en el **mismo día del mes** que el desembolso.
- Si ese día no existe (ej. 31), vence el **último día del mes**.
- Ejemplo: Desembolso 2025-01-31
  - Ciclo 1 DueDate: 2025-02-28 (o 29)
  - Ciclo 2 DueDate: 2025-03-31

---

## 4) Generación de ciclos
- Al crear un préstamo, se genera al menos el **primer ciclo**.
- Job local: siempre debe existir al menos 1 ciclo futuro pendiente para cada préstamo activo.
- Restricción: no crear ciclos duplicados (Unique LoanId + DueDate).

---

## 5) Cálculo de interés (interés simple)
### 5.1 Base del interés
- Interés se calcula sobre **saldo de capital** (`Loan.PrincipalBalance`) al momento de **generar el ciclo**.

### 5.2 Fórmulas
- Interés mensual esperado:
  - `InterestExpected = round(PrincipalBalance * MonthlyInterestRate, 2)`
- Interés quincenal esperado:
  - `InterestExpected = round(PrincipalBalance * (MonthlyInterestRate / 2), 2)`

---

## 6) Aplicación de pagos (default)
### 6.1 Orden por defecto
1) Interés vencido (ciclos más antiguos con `InterestPending > 0` y DueDate < hoy)
2) Interés del ciclo actual (DueDate dentro del periodo)
3) Capital

### 6.2 Restricción V1 de excedentes
- V1 recomendado: **no permitir** que el pago deje “excedente no aplicable”.
- Si el pago excede interés pendiente + capital, mostrar error: “Monto excede lo adeudado”.

---

## 7) Capitalización de interés no pagado (global)
Si `AppSettings.CapitalizeUnpaidInterest = 1`:
- Cuando un ciclo pasa a vencido y tiene `InterestPending > 0`, se permite capitalizar.
- V1 regla operativa: capitalización se ejecuta automáticamente en el job local diario (o al abrir app) sobre ciclos vencidos no capitalizados.
- Efecto:
  - `Loan.PrincipalBalance += InterestPending`
  - `BillingCycle.IsCapitalized = 1`
  - `BillingCycle.CapitalizedAmount = InterestPending`
  - `BillingCycle.InterestPending = 0`
  - `BillingCycle.Status = 'CLOSED'`
  - Registrar `LoanEvent`.

Si está en 0:
- El interés pendiente permanece como interés por cobrar.

---

## 8) Mora (regla simple V1)
- Un préstamo está en mora si:
  - Existe al menos un ciclo con `DueDate < hoy - MoratoriumDays` y `InterestPending > 0`.
- El cliente se marca “en mora” si **cualquier préstamo** está en mora.

---

## 9) Definiciones de KPIs / Reportes (fórmulas)
### 9.1 Capital colocado (Dinero regado)
- Suma de `Loan.PrincipalBalance` de préstamos con Status `ACTIVE` o `IN_MORA`.

### 9.2 Capital pendiente por recuperar
- Igual a Capital colocado (en V1 no hay cartera vendida ni castigos).

### 9.3 Interés cobrado del mes
- Suma de `PaymentAllocation.Amount` donde `AllocationType='INTEREST'` y `PaymentDate` dentro del mes.

### 9.4 Interés pendiente total
- Suma de `BillingCycle.InterestPending` para préstamos activos.

### 9.5 A cobrar (quincena/mes)
- Para un periodo P:
  - Interés esperado del periodo: suma de `BillingCycle.InterestExpected` con `DueDate` dentro de P y Status no cerrado.
  - Más atrasados (si filtro “Atrasados”): suma de `InterestPending` en ciclos vencidos.

### 9.6 Morosos (conteo)
- Conteo de clientes con al menos 1 préstamo en mora (ver regla 8).

---

## 10) Validación de DNI Único (opcional)
Si `AppSettings.ValidateDni = 1`:
- Al crear o editar un cliente, se verifica que no exista otro cliente con el mismo DNI.
- La comparación es **case-insensitive** (Ej: "001-010100-0000A" = "001-010100-0000a").
- Si encuentra duplicado, se **rechaza** el guardado y muestra información del cliente existente.
- En modo edición, se excluye al cliente actual de la validación.

Si está en 0:
- Se permite registrar clientes con DNI duplicado.

---

## 11) Criterios de consistencia (sanity checks)
- `BillingCycle.InterestPending = max(InterestExpected - InterestPaid, 0)`
- `Loan.PrincipalBalance = PrincipalOriginal - sum(PaymentAllocation PRINCIPAL validas)` (+ sum(capitalizaciones) si aplica)
- Si un préstamo llega a `PrincipalBalance=0` y no hay interés pendiente, Status → `CLOSED`.
