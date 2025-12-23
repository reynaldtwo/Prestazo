# Modelo de Base de Datos (SQLite) – App Préstamos Informales V1 (100% Local)

## 1) Objetivo del modelo
Este modelo soporta la V1 de una app **offline-first** para prestamistas informales, con BD **SQLite embebida**, enfocada en:
- Registrar clientes y préstamos.
- Gestionar **ciclos de cobro** (quincenal/mensual) con intereses simples.
- Registrar pagos flexibles (interés/capital/mixto) con **trazabilidad** (cómo se aplicó cada pago).
- Manejar mora simple.
- Generar reportes básicos (capital colocado, interés cobrado, pendientes, morosos).
- Configurar reglas globales (capitalización de interés, tolerancia de mora, etc.).

> Nota: Este documento describe el **modelo lógico** (entidades, relaciones y reglas). No incluye scripts/DDL.

---

## 2) Entidades (tablas) incluidas en V1
Tablas núcleo:
1. **AppSettings**
2. **Customer**
3. **Loan**
4. **BillingCycle**
5. **Payment**
6. **PaymentAllocation**
7. **AuditLog**

Tabla recomendada para robustez (V1):
8. **LoanEvent** (para capitalización de interés y eventos relevantes del préstamo)

---

## 3) Diagrama lógico (ASCII ERD)
```
AppSettings (1)

Customer (1) ──< Loan (N) ──< BillingCycle (N)
                  │
                  └──< Payment (N) ──< PaymentAllocation (N) >──(0/1) BillingCycle
                                           │
                                           └──(N) -> Loan (para asignación a capital)

Loan (1) ──< LoanEvent (N)     (recomendado para trazabilidad)
```

---

## 4) Descripción de tablas y propósito

### 4.1 AppSettings (configuración global)
**Propósito:** almacenar políticas generales del negocio aplicables a la operación y cálculos.
- Capitalizar interés no pagado: Sí/No
- Días de tolerancia de mora
- Regla de aplicación de pagos (interés primero vs capital primero)
- Consecutivo de comprobantes internos
- Moneda principal (NIO)

**Cardinalidad:** 1 registro (o formato clave/valor).

---

### 4.2 Customer (cliente)
**Propósito:** datos maestros del cliente + configuración operativa de cobro.
Incluye:
- Identidad (nombre, alias/apodo)
- Contacto (teléfono)
- Ubicación (dirección/referencia)
- Estado (activo/inactivo)
- **Frecuencia de cobro por cliente**: Quincenal/Mensual
- Día preferido de cobro (opcional)

**Relaciones:**
- Customer (1) → Loan (N)

---

### 4.3 Loan (préstamo)
**Propósito:** registrar cada préstamo otorgado a un cliente y su situación actual.
Incluye:
- Capital inicial
- Tasa mensual (%)
- Fecha de desembolso
- Saldo de capital actual (para consultas rápidas)
- Estado: Activo / En mora / Cancelado
- Notas

**Relaciones:**
- Loan (N) pertenece a Customer (1)
- Loan (1) → BillingCycle (N)
- Loan (1) → Payment (N)
- Loan (1) → LoanEvent (N) (recomendado)

---

### 4.4 BillingCycle (ciclo de cobro)
**Propósito:** modelar la lógica real del prestamista informal: “este mes/quincena me toca cobrar interés X”.
Cada ciclo guarda:
- Inicio/fin del ciclo
- Fecha de vencimiento (DueDate)
- Interés esperado del ciclo
- Interés pagado
- Interés pendiente
- Estado: Pendiente / Pagado / Vencido
- Metadatos de cierre/capitalización (si aplica)

**Relaciones:**
- BillingCycle (N) pertenece a Loan (1)
- BillingCycle puede ser referenciado por PaymentAllocation cuando se paga interés

---

### 4.5 Payment (pago)
**Propósito:** registrar cada pago recibido del cliente (hecho contable).
Incluye:
- Fecha de pago
- Monto total
- Tipo declarado: Interés / Capital / Mixto (informativo para UX)
- Número de comprobante interno
- Estado: Válido / Anulado (con motivo)
- Nota

**Regla V1 clave:** un pago **no se edita**; se permite anulación con motivo.

**Relaciones:**
- Payment (N) pertenece a Loan (1)
- Payment (1) → PaymentAllocation (N)

---

### 4.6 PaymentAllocation (distribución del pago)
**Propósito:** trazabilidad completa de cómo se aplicó un pago.
Un mismo pago puede dividirse en varias asignaciones, por ejemplo:
- Parte a interés vencido de un BillingCycle
- Parte a interés del ciclo actual
- Parte a capital del Loan

Cada asignación debe indicar:
- PaymentId
- AllocationType: INTEREST | PRINCIPAL
- Amount
- Si AllocationType = INTEREST: BillingCycleId (obligatorio)
- Si AllocationType = PRINCIPAL: LoanId (referencia al préstamo)

**Relaciones:**
- PaymentAllocation (N) pertenece a Payment (1)
- PaymentAllocation (0/1) referencia BillingCycle (si es interés)
- PaymentAllocation (1) referencia Loan (si es capital)

---

### 4.7 AuditLog (auditoría mínima)
**Propósito:** registrar acciones críticas para confiabilidad y resolución de disputas.
Eventos mínimos:
- Crear préstamo
- Registrar pago
- Anular pago
- Ejecutar capitalización
- Cambiar políticas (AppSettings)

**Relaciones:**
- Puede referenciar CustomerId, LoanId, PaymentId (según evento).

---

### 4.8 LoanEvent (recomendado)
**Propósito:** trazabilidad robusta de eventos del préstamo (especialmente capitalización de interés).
Eventos típicos:
- CAPITALIZATION_APPLIED (monto capitalizado, ciclo afectado, timestamp)
- STATUS_CHANGE (activo/mora/cancelado)
- RATE_CHANGE (si se habilita en futuro)

**Por qué se recomienda:** la capitalización modifica saldos y debe quedar **explicada** sin ambigüedad.

---

## 5) Reglas de negocio soportadas por el modelo

### 5.1 Frecuencia de cobro por cliente
- Customer define Quincenal/Mensual.
- La generación de BillingCycle para cada Loan se basa en esa frecuencia (o se “ancla” a la fecha de desembolso).

### 5.2 Cálculo de interés por ciclo (interés simple)
- El interés esperado del ciclo se calcula sobre **saldo de capital** (recomendado).
- Quincenal: interés mensual / 2 (regla simple V1).

### 5.3 Aplicación automática de pagos (default)
- Orden de aplicación recomendado:
  1) Interés vencido (ciclos más antiguos)
  2) Interés del ciclo actual
  3) Capital
- La app registra esta aplicación en PaymentAllocation.

### 5.4 Capitalización de interés no pagado (config global)
Si AppSettings.CapitalizeUnpaidInterest = Sí:
- Al vencer un ciclo, el interés pendiente puede sumarse al capital del préstamo.
- Debe registrarse en LoanEvent (o campos de BillingCycle) para trazabilidad.

### 5.5 Mora
- Un préstamo entra en mora si:
  - Existen ciclos vencidos con interés pendiente y
  - Han transcurrido más de X días (AppSettings) desde DueDate sin pago suficiente.

---

## 6) Integridad, restricciones y consistencia (conceptual)

### 6.1 Integridad referencial
- Loan debe referenciar un Customer existente.
- BillingCycle debe referenciar un Loan existente.
- Payment debe referenciar un Loan existente.
- PaymentAllocation debe referenciar un Payment existente.
- PaymentAllocation:
  - Si INTEREST: BillingCycleId obligatorio
  - Si PRINCIPAL: LoanId obligatorio

### 6.2 Inmutabilidad de pagos
- Payment no se actualiza para cambiar montos.
- Anulación: marcar estado y registrar motivo; opcionalmente crear asiento compensatorio en futuro.

### 6.3 No negativos
- Loan.SaldoCapital ≥ 0
- BillingCycle.InteresPendiente ≥ 0
- PaymentAllocation.Amount > 0

### 6.4 Redondeo
- Todos los montos se manejan con redondeo consistente (2 decimales) para evitar diferencias acumuladas.

---

## 7) Índices recomendados (para rendimiento en SQLite)
- Customer: (BillingFrequency, Status) para pantalla “A Cobrar”.
- Loan: (CustomerId, Status) para cartera activa.
- BillingCycle:
  - (LoanId, DueDate)
  - Unique (LoanId, DueDate) para evitar ciclos duplicados.
- Payment:
  - (LoanId, PaymentDate)
- PaymentAllocation:
  - (PaymentId)
  - (BillingCycleId) para auditoría y reportes de interés

---

## 8) Consultas clave que habilita el modelo (sin SQL)
- **A Cobrar (quincena/mes):** clientes con BillingCycle pendiente/vencido dentro del periodo, agrupado por cliente.
- **Dinero regado / capital colocado:** suma de Loan.SaldoCapital en préstamos activos.
- **Interés cobrado del mes:** suma de PaymentAllocation de tipo INTEREST en rango de fechas.
- **Interés pendiente:** suma BillingCycle.InteresPendiente en préstamos activos.
- **Morosos:** clientes con BillingCycle vencidos, interés pendiente y días > tolerancia.

---

## 9) Alcance futuro (compatibilidad)
Este modelo es extensible a V1.1+ para:
- Exportación a Excel/CSV
- Multiusuario local (roles)
- Recordatorios
- Sincronización (si se migra a servidor)
- Cambio de tasa/reestructuras (apoyado por LoanEvent)
