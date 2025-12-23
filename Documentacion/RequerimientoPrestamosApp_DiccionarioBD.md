# Diccionario de Datos (SQLite) – App Préstamos Informales V1 (100% Local)

## 0) Convenciones y decisiones V1
- BD: SQLite (local).
- Claves primarias: `TEXT` (UUID) o `INTEGER` autoincremental. Recomendación V1: **UUID en TEXT** para portabilidad y evitar colisiones futuras.
- Fechas: `TEXT` en formato ISO-8601 (`YYYY-MM-DD` o `YYYY-MM-DDTHH:MM:SS`).
- Montos: `NUMERIC` (en SQLite es afinidad; usar redondeo a 2 decimales en lógica de app).
- Soft-delete: No requerido en V1 (excepto anulación de pagos).
- Auditoría: mínima vía `AuditLog` + eventos en `LoanEvent`.

> Este documento define **tablas, campos, tipos, reglas, FKs, índices**. No incluye scripts DDL.

---

## 1) Tabla: AppSettings
**Propósito:** políticas globales del negocio (1 registro).

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| SettingsId | TEXT | No | `'global'` | PK fijo (1 registro). |
| BaseCurrency | TEXT | No | `'NIO'` | Moneda principal. |
| CapitalizeUnpaidInterest | INTEGER | No | 0 | 0=No, 1=Sí. |
| MoratoriumDays | INTEGER | No | 7 | Días de tolerancia para mora. |
| PaymentApplyOrder | TEXT | No | `'INTEREST_FIRST'` | `'INTEREST_FIRST'` o `'PRINCIPAL_FIRST'`. |
| DeriveBiweeklyRate | INTEGER | No | 1 | 1 = mensual/2, 0 = tasa quincenal explícita (si se habilita). |
| ReceiptNextNumber | INTEGER | No | 1 | Consecutivo interno. |
| DefaultBillingFrequency | TEXT | No | `'MONTHLY'` | `'BIWEEKLY'` o `'MONTHLY'`. |
| CreatedAt | TEXT | No | (now) | ISO datetime. |
| UpdatedAt | TEXT | No | (now) | ISO datetime. |

**Índices:** no aplica (1 registro).

---

## 2) Tabla: Customer
**Propósito:** maestro de clientes + configuración de cobro.

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| CustomerId | TEXT | No |  | PK (UUID). |
| FullName | TEXT | No |  | Nombre. |
| Alias | TEXT | Sí |  | Apodo (para búsqueda). |
| Phone | TEXT | Sí |  | Teléfono. |
| Address | TEXT | Sí |  | Dirección/referencia. |
| Notes | TEXT | Sí |  | Nota interna. |
| Status | TEXT | No | `'ACTIVE'` | `'ACTIVE'` / `'INACTIVE'`. |
| BillingFrequency | TEXT | No |  | `'BIWEEKLY'` / `'MONTHLY'`. |
| PreferredPayDay | INTEGER | Sí |  | Día preferido (1–31) si aplica. |
| CreatedAt | TEXT | No | (now) |  |
| UpdatedAt | TEXT | No | (now) |  |

**Restricciones recomendadas:**
- `Status IN ('ACTIVE','INACTIVE')`
- `BillingFrequency IN ('BIWEEKLY','MONTHLY')`
- `PreferredPayDay` entre 1 y 31 si no es nulo.

**Índices recomendados:**
- `IDX_Customer_Frequency_Status (BillingFrequency, Status)`
- `IDX_Customer_Name (FullName)`
- `IDX_Customer_Alias (Alias)` (si se usa búsqueda por alias)

---

## 3) Tabla: Loan
**Propósito:** préstamo otorgado a un cliente y su estado actual.

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| LoanId | TEXT | No |  | PK (UUID). |
| CustomerId | TEXT | No |  | FK → Customer.CustomerId. |
| PrincipalOriginal | NUMERIC | No |  | Capital inicial. |
| PrincipalBalance | NUMERIC | No |  | Saldo de capital actual (≥ 0). |
| MonthlyInterestRate | NUMERIC | No |  | Ej: 0.20 para 20% (o 20, según convención; definir una sola). |
| RateUnit | TEXT | No | `'MONTHLY'` | V1: `'MONTHLY'` fijo (evita confusión). |
| DisbursementDate | TEXT | No |  | Fecha desembolso (YYYY-MM-DD). |
| Status | TEXT | No | `'ACTIVE'` | `'ACTIVE'` / `'IN_MORA'` / `'CLOSED'`. |
| ClosedAt | TEXT | Sí |  | Fecha cierre si saldo=0. |
| Notes | TEXT | Sí |  |  |
| CreatedAt | TEXT | No | (now) |  |
| UpdatedAt | TEXT | No | (now) |  |

**Restricciones recomendadas:**
- `PrincipalOriginal > 0`
- `PrincipalBalance >= 0`
- `Status IN ('ACTIVE','IN_MORA','CLOSED')`

**FK:**
- `CustomerId` referencia Customer. (ON DELETE RESTRICT recomendado)

**Índices recomendados:**
- `IDX_Loan_Customer_Status (CustomerId, Status)`
- `IDX_Loan_Status (Status)`

---

## 4) Tabla: BillingCycle
**Propósito:** ciclos de cobro por préstamo (quincenal/mensual) para interés esperado, pagado y pendiente.

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| BillingCycleId | TEXT | No |  | PK (UUID). |
| LoanId | TEXT | No |  | FK → Loan.LoanId. |
| CycleNumber | INTEGER | No |  | Secuencia incremental por préstamo. |
| Frequency | TEXT | No |  | Copia de frecuencia al momento de crear ciclo (`BIWEEKLY`/`MONTHLY`). |
| PeriodStartDate | TEXT | No |  | YYYY-MM-DD. |
| PeriodEndDate | TEXT | No |  | YYYY-MM-DD. |
| DueDate | TEXT | No |  | Fecha objetivo de cobro. |
| InterestExpected | NUMERIC | No | 0 | Interés esperado del ciclo. |
| InterestPaid | NUMERIC | No | 0 | Interés pagado acumulado. |
| InterestPending | NUMERIC | No | 0 | InterestExpected - InterestPaid (≥ 0). |
| Status | TEXT | No | `'PENDING'` | `'PENDING'` / `'PAID'` / `'OVERDUE'` / `'CLOSED'`. |
| ClosedAt | TEXT | Sí |  | Cierre del ciclo. |
| IsCapitalized | INTEGER | No | 0 | 1 si el interés pendiente fue capitalizado. |
| CapitalizedAmount | NUMERIC | No | 0 | Monto capitalizado (si aplica). |
| CapitalizedAt | TEXT | Sí |  | Timestamp capitalización. |
| CreatedAt | TEXT | No | (now) |  |
| UpdatedAt | TEXT | No | (now) |  |

**Restricciones recomendadas:**
- `Frequency IN ('BIWEEKLY','MONTHLY')`
- `Status IN ('PENDING','PAID','OVERDUE','CLOSED')`
- `InterestExpected >= 0`, `InterestPaid >= 0`, `InterestPending >= 0`
- `CycleNumber >= 1`

**FK:**
- `LoanId` referencia Loan. (ON DELETE RESTRICT recomendado)

**Índices recomendados:**
- `UQ_BillingCycle_Loan_DueDate (LoanId, DueDate)` **único** para evitar ciclos duplicados.
- `IDX_BillingCycle_Loan_Status (LoanId, Status)`
- `IDX_BillingCycle_DueDate_Status (DueDate, Status)` para “A Cobrar”.

---

## 5) Tabla: Payment
**Propósito:** registro del pago (hecho), independiente de cómo se aplicó.

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| PaymentId | TEXT | No |  | PK (UUID). |
| LoanId | TEXT | No |  | FK → Loan.LoanId. |
| CustomerId | TEXT | No |  | Denormalización para consultas rápidas (debe coincidir con Loan.CustomerId). |
| PaymentDate | TEXT | No |  | Fecha/hora ISO. |
| Amount | NUMERIC | No |  | Monto total (>0). |
| DeclaredType | TEXT | No | `'MIXED'` | `'INTEREST'/'PRINCIPAL'/'MIXED'` (informativo). |
| ReceiptNumber | INTEGER | No |  | Consecutivo interno. |
| Status | TEXT | No | `'VALID'` | `'VALID'` / `'VOIDED'`. |
| VoidReason | TEXT | Sí |  | Motivo anulación. |
| VoidedAt | TEXT | Sí |  | Timestamp anulación. |
| Notes | TEXT | Sí |  |  |
| CreatedAt | TEXT | No | (now) |  |
| UpdatedAt | TEXT | No | (now) |  |

**Restricciones recomendadas:**
- `Amount > 0`
- `DeclaredType IN ('INTEREST','PRINCIPAL','MIXED')`
- `Status IN ('VALID','VOIDED')`
- Si `Status='VOIDED'` entonces `VoidReason` no nulo.

**FK:**
- `LoanId` → Loan
- `CustomerId` → Customer (opcionalmente sin FK estricta si se prioriza performance; recomendado mantener FK).

**Índices recomendados:**
- `IDX_Payment_Loan_Date (LoanId, PaymentDate)`
- `IDX_Payment_Customer_Date (CustomerId, PaymentDate)`
- `UQ_Payment_ReceiptNumber (ReceiptNumber)` **único** (por simplicidad V1, global).

---

## 6) Tabla: PaymentAllocation
**Propósito:** distribución trazable del pago a interés (por ciclo) y/o capital.

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| AllocationId | TEXT | No |  | PK (UUID). |
| PaymentId | TEXT | No |  | FK → Payment.PaymentId. |
| LoanId | TEXT | No |  | FK → Loan.LoanId (siempre). |
| AllocationType | TEXT | No |  | `'INTEREST'` o `'PRINCIPAL'`. |
| Amount | NUMERIC | No |  | >0 |
| BillingCycleId | TEXT | Sí |  | FK → BillingCycle.BillingCycleId (obligatorio si INTEREST). |
| CreatedAt | TEXT | No | (now) |  |

**Restricciones recomendadas:**
- `AllocationType IN ('INTEREST','PRINCIPAL')`
- `Amount > 0`
- Regla: si `AllocationType='INTEREST'` entonces `BillingCycleId` **no nulo**.
- Regla: si `AllocationType='PRINCIPAL'` entonces `BillingCycleId` **nulo**.

**FK:**
- `PaymentId` → Payment (ON DELETE CASCADE recomendado: si se borra un pago por mantenimiento, se borran allocations; en V1 normalmente no se borra).
- `LoanId` → Loan
- `BillingCycleId` → BillingCycle (solo para interés)

**Índices recomendados:**
- `IDX_Allocation_Payment (PaymentId)`
- `IDX_Allocation_Cycle (BillingCycleId)`
- `IDX_Allocation_Loan (LoanId)`

---

## 7) Tabla: LoanEvent (recomendada)
**Propósito:** trazabilidad robusta de eventos del préstamo (especialmente capitalización).

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| LoanEventId | TEXT | No |  | PK (UUID). |
| LoanId | TEXT | No |  | FK → Loan.LoanId. |
| EventType | TEXT | No |  | `'CAPITALIZATION_APPLIED'`, `'STATUS_CHANGED'`, etc. |
| RelatedBillingCycleId | TEXT | Sí |  | FK → BillingCycle (si aplica). |
| RelatedPaymentId | TEXT | Sí |  | FK → Payment (si aplica). |
| Amount | NUMERIC | Sí |  | Monto asociado (ej. capitalizado). |
| OldValue | TEXT | Sí |  | Para cambios (status/tasa). |
| NewValue | TEXT | Sí |  |  |
| Notes | TEXT | Sí |  |  |
| CreatedAt | TEXT | No | (now) |  |

**Índices recomendados:**
- `IDX_LoanEvent_Loan_Date (LoanId, CreatedAt)`
- `IDX_LoanEvent_Type (EventType)`

---

## 8) Tabla: AuditLog
**Propósito:** auditoría mínima transversal (usuario/dispositivo local).

| Campo | Tipo | Nulo | Default | Reglas/Notas |
|---|---|---:|---|---|
| AuditLogId | TEXT | No |  | PK (UUID). |
| Action | TEXT | No |  | `'CREATE_LOAN'`, `'RECORD_PAYMENT'`, `'VOID_PAYMENT'`, `'UPDATE_SETTINGS'`, etc. |
| EntityType | TEXT | No |  | `'Customer'/'Loan'/'Payment'/'BillingCycle'/'Settings'`. |
| EntityId | TEXT | No |  | Id del registro afectado. |
| Details | TEXT | Sí |  | JSON/texto libre con contexto. |
| CreatedAt | TEXT | No | (now) |  |

**Índices recomendados:**
- `IDX_Audit_Action_Date (Action, CreatedAt)`
- `IDX_Audit_Entity (EntityType, EntityId)`

---

## 9) Reglas transaccionales (qué se toca en cada operación)
### 9.1 Crear cliente
- Insert `Customer`.
- Insert `AuditLog`.

### 9.2 Crear préstamo
- Insert `Loan` (PrincipalBalance = PrincipalOriginal).
- Generar ciclos iniciales (al menos 1 próximo ciclo) → Insert `BillingCycle`.
- Insert `AuditLog` (+ opcional `LoanEvent` CREATE).

### 9.3 Generar/Extender ciclos (job local)
- Para cada `Loan` activo, si no existe un ciclo que cubra el próximo periodo, crear `BillingCycle` nuevo.
- Mantener `UQ (LoanId, DueDate)` para evitar duplicados.

### 9.4 Registrar pago (VALID)
Transacción atómica:
1) Insert `Payment`.
2) Insert `PaymentAllocation` (una o varias filas) según orden de aplicación.
3) Update `BillingCycle` afectado: InterestPaid/InterestPending/Status.
4) Update `Loan`: PrincipalBalance (si hubo asignación a capital); Status (si cambia).
5) Insert `AuditLog` (y opcional `LoanEvent`).

### 9.5 Anular pago (VOIDED)
Transacción atómica:
1) Update `Payment`: Status='VOIDED', VoidReason, VoidedAt.
2) Reversar efectos:
   - Recalcular `BillingCycle` InterestPaid/InterestPending o registrar reversos en allocations (en V1 se recomienda recalcular desde allocations VALID).
   - Recalcular `Loan.PrincipalBalance` desde allocations PRINCIPAL válidas.
3) Insert `AuditLog` + `LoanEvent` (VOID).

> En V1, para robustez: recalcular saldos desde allocations válidas evita errores acumulados.

### 9.6 Capitalizar interés vencido (si setting activo)
Transacción atómica por ciclo vencido:
1) Determinar InterestPending.
2) Update `Loan.PrincipalBalance += InterestPending`.
3) Update `BillingCycle`: IsCapitalized=1, CapitalizedAmount, CapitalizedAt, InterestPending=0, Status='CLOSED'.
4) Insert `LoanEvent` CAPITALIZATION_APPLIED.
5) Insert `AuditLog`.

---

## 10) Notas críticas de implementación (para evitar errores)
- Definir una convención única para tasas: recomendado guardar `MonthlyInterestRate` como **decimal** (ej. 0.20) y no como 20.
- Usar transacciones SQLite en pagos/anulaciones/capitalizaciones.
- Mantener `ReceiptNumber` único y consistente con `AppSettings.ReceiptNextNumber`.
- Redondeo: aplicar redondeo a 2 decimales en cada operación que actualiza saldos.
- Evitar “saldo fuente de verdad” ambiguo: el saldo en Loan es caché; la trazabilidad real está en PaymentAllocation + BillingCycle.

---

## 11) Archivos/entregables derivados (siguiente paso recomendado)
- Especificación de consultas para pantalla “A Cobrar” y dashboard.
- Casos de prueba (datasets) para validar: pagos parciales, atrasos, capitalización ON/OFF, anulación.
