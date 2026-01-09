# Prestazo — Pagos Multimoneda y Diferencial Cambiario (Paso 1 + Paso 2)
**Documento para desarrollo (Flutter + BD local)**  
**Fecha:** 2026-01-07  
**Alcance:** Implementación robusta de pagos en múltiples monedas, trazabilidad de tasa aplicada, distribución (allocations) y cálculo/reporting de diferencial cambiario.

---

## 0) Objetivo y principios (no negociables)

### 0.1 Objetivo funcional
Permitir que un **préstamo** esté en una moneda (por ejemplo, `NIO`) y el **pago** se reciba en otra (por ejemplo, `USD`), sin perder:
- Trazabilidad de la moneda real pagada.
- Tasa usada (y por qué se usó).
- Monto aplicado al préstamo (en moneda del préstamo).
- Monto equivalente en moneda base (para dashboard).
- Ganancia/pérdida por diferencial cambiario, calculable y auditable.

### 0.2 Principios de robustez
1. **Nunca perder el “monto original del pago”** (la moneda y monto con que realmente pagó el cliente).
2. **Nunca recalcular históricamente usando tasas nuevas**. Toda tasa usada debe quedar congelada (snapshot).
3. **Evitar flotantes para dinero**. Usar *minor units* (enteros) o un tipo decimal exacto.
4. **Atomicidad**: registrar un pago y sus efectos debe ser una sola transacción (todo o nada).
5. **Idempotencia**: si el pago se reintenta (offline/online), no debe duplicarse.

---

## 1) Glosario de monedas (definiciones exactas)

> Estas definiciones se usan en todo el sistema (BD, lógica y UI).

- **LoanCurrency**: moneda contractual del préstamo (`loans.currency_code`).  
  El **saldo oficial** del préstamo (`principal_balance`) vive en esta moneda.

- **PaymentCurrency**: moneda en la que el prestamista recibió el dinero del cliente (`payments.payment_currency`).

- **BaseCurrency**: moneda funcional para métricas internas (dashboard consolidado).  
  La define `app_settings.baseCurrency`.

- **ReportCurrency**: moneda elegida para reportes globales (no cambia cálculos).  
  La define `app_settings.reportCurrency`.

- **DisplayCurrency** (si existe en UI): moneda para mostrar en pantallas/dashboards (solo presentación).

---

## 2) Convención de tasa de cambio (obligatoria)

### 2.1 Convención única para almacenar tasas
Para evitar ambigüedad, toda tasa debe cumplir esta convención:

> **rate = (BaseCurrency minor units) por 1 unidad de ForeignCurrency**

Ejemplo si Base=NIO y Foreign=USD:
- buy_rate = 36.00 (NIO por 1 USD)
- sell_rate = 37.00 (NIO por 1 USD)

### 2.2 Regla de dirección (BUY vs SELL) — automática, no por “intuición”
- **Foreign → Base** (ej. USD → NIO): usar **BUY** de la moneda foreign.
  - Fórmula: `base = foreign * buy_rate`
- **Base → Foreign** (ej. NIO → USD): usar **SELL** de la moneda foreign.
  - Fórmula: `foreign = base / sell_rate`

### 2.3 No permitir “invertir” BUY/SELL sin intención explícita
Si el usuario quiere “ganar más” con FX, eso se implementa de forma controlada mediante:
- spread configurable, o
- tasas proveedor (buy/sell), o
- tasa manual (con auditoría).

No se debe permitir que el usuario elija BUY/SELL incorrecto “porque sí”, ya que rompe la coherencia del sistema.

---

# PASO 1 — Ampliación de esquema de BD (mínimo para multimoneda + FX auditable)

> **Estado actual (según documento del proyecto):**  
> - `loans` tiene `principal_balance` y `currency_code`.  
> - `payments` tiene `amount`, `payment_currency`, `exchange_rate_applied`, `exchange_profit`.  
> - `payment_allocations` tiene `allocation_type` (INTEREST/PRINCIPAL) y `amount`.  
> - `exchange_rates` tiene `source_currency`, `target_currency`, `buy_rate`, `sell_rate`, `rate_date`.  
>
> Problema: `amount` en pagos y allocations es **ambiguo** (¿en qué moneda?).

---

## 1.1 Recomendación crítica: dinero en “minor units”
### Opción A (recomendada, a prueba de todo)
- Guardar dinero como **INTEGER** en minor units: centavos, etc.
- Requiere una tabla/servicio de moneda para saber `fractionDigits` por ISO.

### Opción B (si no migran todavía)
- Mantener `REAL`, pero se vuelve vulnerable a errores de redondeo (no recomendado).
- Si eligen esto, deberán usar una librería Decimal en Dart y guardar como TEXT/DECIMAL en BD.

**Este documento asume Opción A** (porque pediste “a prueba de todo”).  
Si no la adoptan, deben documentar el riesgo y mitigaciones.

---

## 1.2 Tabla `currencies` (si aún no existe)
Necesaria para:
- decimales por moneda (JPY=0, USD=2, KWD=3)
- símbolo, nombre (para UI multilenguaje)

**DDL orientativo (SQLite):**
```sql
CREATE TABLE IF NOT EXISTS currencies (
  currency_code TEXT PRIMARY KEY,            -- ISO 4217, ej. USD
  fraction_digits INTEGER NOT NULL,          -- 0,2,3...
  symbol TEXT NULL,                          -- $, C$, etc (solo display)
  name_key TEXT NOT NULL,                    -- i18n key, ej "currency.usd"
  is_active INTEGER NOT NULL DEFAULT 1,      -- 0/1
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_currencies_active ON currencies(is_active);
```

> **Multilenguaje:** `name_key` se resuelve en la app con i18n (ARB/Intl).  
> Nunca guardar “Dólar”, “Dollar” como texto fijo en BD.

---

## 1.3 Normalizar `exchange_rates` para evitar confusión
### Regla obligatoria de contenido en `exchange_rates`
- `source_currency` **debe ser BaseCurrency**
- `target_currency` **debe ser ForeignCurrency**
- `buy_rate` y `sell_rate` siguen la convención Base per 1 Foreign

**Índice de unicidad recomendado:**
```sql
CREATE UNIQUE INDEX IF NOT EXISTS ux_exchange_rates_pair_date
ON exchange_rates(source_currency, target_currency, rate_date);
```

**Campos opcionales recomendados:**
- `provider` (TEXT): origen de tasa
- `captured_at` (TEXT): timestamp real de captura
- `is_offline` (INT 0/1): si la tasa fue usada offline

---

## 1.4 Expandir `payments` (cambios mínimos obligatorios)

### Problema a resolver
`payments.amount` hoy no aclara si es:
- monto en moneda del pago,
- monto en moneda del préstamo,
- o en moneda base.

### Solución mínima robusta
Agregar columnas explícitas en minor units:

**Nuevas columnas (obligatorias):**
- `amount_payment_minor` INTEGER NOT NULL  
- `amount_loan_minor` INTEGER NOT NULL  
- `amount_base_minor` INTEGER NOT NULL  
- `payment_currency` TEXT NOT NULL (siempre, no opcional)
- `loan_currency` TEXT NOT NULL (snapshot por auditoría; aunque existe en `loans`)

**Snapshot de FX aplicado (obligatorio cuando payment_currency != loan_currency):**
- `rate_id` TEXT NULL  (FK a exchange_rates)
- `rate_type_used` TEXT NULL  (`BUY|SELL|MID|MANUAL`)
- `rate_value_used` REAL NULL (valor exacto usado)
- `rate_date_used` TEXT NULL  (fecha efectiva de tasa)
- `reference_rate_value` REAL NULL (para cálculo de diferencial, típicamente MID)
- `fx_profit_base_minor` INTEGER NULL (ganancia FX en BaseCurrency minor units)

**Estados adicionales recomendados:**
- `fx_status` TEXT NOT NULL DEFAULT 'NONE' (`NONE|APPLIED|PENDING_CONFIRMATION`)
- `idempotency_key` TEXT NULL (único si existe sincronización)

**DDL orientativo (SQLite, ALTER):**
```sql
ALTER TABLE payments ADD COLUMN amount_payment_minor INTEGER;
ALTER TABLE payments ADD COLUMN amount_loan_minor INTEGER;
ALTER TABLE payments ADD COLUMN amount_base_minor INTEGER;
ALTER TABLE payments ADD COLUMN loan_currency TEXT;
ALTER TABLE payments ADD COLUMN rate_id TEXT;
ALTER TABLE payments ADD COLUMN rate_type_used TEXT;
ALTER TABLE payments ADD COLUMN rate_value_used REAL;
ALTER TABLE payments ADD COLUMN rate_date_used TEXT;
ALTER TABLE payments ADD COLUMN reference_rate_value REAL;
ALTER TABLE payments ADD COLUMN fx_profit_base_minor INTEGER;
ALTER TABLE payments ADD COLUMN fx_status TEXT DEFAULT 'NONE';
ALTER TABLE payments ADD COLUMN idempotency_key TEXT;
```

**Índices recomendados:**
```sql
CREATE INDEX IF NOT EXISTS idx_payments_loan_date ON payments(loan_id, payment_date);
CREATE UNIQUE INDEX IF NOT EXISTS ux_payments_idempotency ON payments(idempotency_key)
WHERE idempotency_key IS NOT NULL;
```

> Nota: SQLite no soporta agregar NOT NULL fácilmente en ALTER.  
> En migración real, se recomienda: crear tabla nueva, copiar datos, renombrar.

---

## 1.5 Expandir `payment_allocations` (para que la distribución sea coherente)

### Regla obligatoria
**Toda allocation se guarda en moneda del préstamo (LoanCurrency) y en minor units.**

**Cambios mínimos:**
- `amount_loan_minor` INTEGER NOT NULL (reemplaza `amount REAL`)
- `allocation_type` debe ser código estable (i18n en UI):
  - mínimo: `INTEREST`, `PRINCIPAL`
  - recomendado extender a: `FEE`, `PENALTY`, `MORATORY_INTEREST`, etc. (si aplica)

**DDL orientativo:**
```sql
ALTER TABLE payment_allocations ADD COLUMN amount_loan_minor INTEGER;
```

**Índices:**
```sql
CREATE INDEX IF NOT EXISTS idx_allocations_payment ON payment_allocations(payment_id);
CREATE INDEX IF NOT EXISTS idx_allocations_cycle ON payment_allocations(billing_cycle_id);
```

---

## 1.6 Nueva tabla `payment_fx_details` (recomendada, para auditoría FX completa)
Aunque parte se puede guardar en `payments`, esta tabla evita mezclar conceptos y hace el reporte fácil.

**Campos:**
- `fx_id` TEXT PK
- `payment_id` TEXT FK
- `base_currency` TEXT
- `payment_currency` TEXT
- `loan_currency` TEXT
- `customer_rate_type` TEXT  (`BUY|SELL|MID|MANUAL`)
- `customer_rate_value` REAL
- `reference_rate_type` TEXT (`MID|PROVIDER_MID|MANUAL_REF`)
- `reference_rate_value` REAL
- `amount_payment_minor` INTEGER
- `amount_base_customer_minor` INTEGER
- `amount_base_reference_minor` INTEGER
- `fx_profit_base_minor` INTEGER
- `created_at` TEXT

**DDL orientativo:**
```sql
CREATE TABLE IF NOT EXISTS payment_fx_details (
  fx_id TEXT PRIMARY KEY,
  payment_id TEXT NOT NULL,
  base_currency TEXT NOT NULL,
  payment_currency TEXT NOT NULL,
  loan_currency TEXT NOT NULL,
  customer_rate_type TEXT NOT NULL,
  customer_rate_value REAL NOT NULL,
  reference_rate_type TEXT NOT NULL,
  reference_rate_value REAL NOT NULL,
  amount_payment_minor INTEGER NOT NULL,
  amount_base_customer_minor INTEGER NOT NULL,
  amount_base_reference_minor INTEGER NOT NULL,
  fx_profit_base_minor INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(payment_id) REFERENCES payments(payment_id)
);

CREATE INDEX IF NOT EXISTS idx_fx_payment ON payment_fx_details(payment_id);
CREATE INDEX IF NOT EXISTS idx_fx_profit ON payment_fx_details(fx_profit_base_minor);
```

---

## 1.7 Migración de datos existentes (sin suposiciones)
Para migrar sin “inventar” significado:

1) **Decidir (por escrito) qué significaba `payments.amount` históricamente**:
   - ¿Era monto en moneda del pago?  
   - ¿En moneda del préstamo?  
   - ¿En base?  
   Si no se puede asegurar, se marca como “legacy_ambiguous”.

2) Estrategia segura:
   - Si `payment_currency` es NULL en un registro legacy:
     - setear `payment_currency = loans.currency_code` (esto es la única inferencia segura).
   - Copiar `amount` a `amount_payment_minor` solo si está confirmado que `amount` era “monto pagado”.
   - Si no, dejar `amount_*_minor` NULL y marcar para corrección manual.

3) No recalcular `exchange_profit` con tasas nuevas.  
   Si ya existía `exchange_profit`, se conserva como legacy y se calcula `fx_profit_base_minor` solo para pagos nuevos.

---

# PASO 2 — Flujo exacto de pago multimoneda + distribución + FX profit

## 2.0 Inputs requeridos (no asumir)
Para registrar un pago, el caso de uso debe recibir explícitamente:

- `loan_id` (UUID)
- `payment_date` (ISO-8601, preferiblemente UTC + offset guardado)
- `declared_type` (`MIXED|INTEREST|PRINCIPAL|CANCEL|RECOVERY`)
- `payment_currency` (ISO 4217)
- `amount_payment_minor` (INTEGER >= 1)
- `notes` (opcional)
- `receipt_number` (opcional)
- `idempotency_key` (opcional pero recomendado; obligatorio si hay sync)

**Si el usuario ingresa tasa manual:**
- `manual_rate_value` (REAL, con la convención Base per 1 Foreign)
- `manual_rate_date` (TEXT)

---

## 2.1 Validaciones (antes de tocar BD)
1) `loan_id` existe y `loans.status` permite pagos (ACTIVE/OVERDUE).  
2) `amount_payment_minor > 0`.  
3) `payment_currency` válida y activa (`currencies.is_active=1`).  
4) Si `declared_type=CANCEL`:
   - calcular deuda total requerida (interés pendiente + capital + otros) y validar si pago cubre o definir política (ver 2.6).
5) Si no hay tasa disponible para conversión requerida:
   - si settings permiten manual: solicitar tasa manual,
   - si no: bloquear pago (no inventar tasa).

---

## 2.2 Resolver monedas del caso
Leer de BD:
- `loan_currency = loans.currency_code`
- `base_currency = app_settings.baseCurrency`
- (opcional) `report_currency = app_settings.reportCurrency`

Reglas:
- Si `payment_currency == loan_currency`: no hay FX para aplicar al préstamo.
- Si difieren: hay FX y se debe resolver tasa y conversiones.

---

## 2.3 Resolución de tasa (rate selection) — algoritmo determinístico

### 2.3.1 Determinar “tipo efectivo” desde settings
Usar `app_settings.paymentRateType` y `allowManualExchangeRate`:

- Si `paymentRateType = PROVIDER_BID_ASK`:
  - Foreign→Base usa BUY
  - Base→Foreign usa SELL
- Si `paymentRateType = MID`:
  - usar `mid = (buy_rate + sell_rate)/2`
- Si `paymentRateType = MANUAL`:
  - requiere `manual_rate_value` (y auditar)
- Si tu app ya define otros valores, documentarlos y mapearlos.

> Importante: el usuario NO elige BUY/SELL arbitrariamente.  
> El sistema lo decide por dirección y settings.

### 2.3.2 Obtener tasas necesarias (posibles escenarios)
**Escenario A: payment_currency == base_currency AND loan_currency != base_currency**
- Se necesita convertir Base→LoanCurrency:
  - usar SELL de loan_currency (porque es Base→Foreign)
  - `loan_amount = base_amount / sell_rate(loan_currency)`

**Escenario B: payment_currency != base_currency AND loan_currency == base_currency**
- Se necesita convertir PaymentCurrency→Base:
  - usar BUY de payment_currency (Foreign→Base)
  - `base_amount = payment_amount * buy_rate(payment_currency)`

**Escenario C: payment_currency != base_currency AND loan_currency != base_currency**
- Conversión en dos pasos vía base:
  1) PaymentCurrency→Base (BUY de payment_currency)
  2) Base→LoanCurrency (SELL de loan_currency)

**Escenario D: payment_currency == base_currency AND loan_currency == base_currency**
- No hay FX.

---

## 2.4 Conversión de montos (minor units) — fórmula + redondeo

### 2.4.1 Utilidad obligatoria: manejo de decimales por moneda
Para convertir entre minor y major:
- `major = minor / 10^fractionDigits`
- `minor = round(major * 10^fractionDigits)`

**Rounding recomendado:** `HALF_UP` (redondeo comercial).  
Documentar si se usa otro.

### 2.4.2 Cálculo de `amount_base_minor`
- Si `payment_currency == base_currency`:
  - `amount_base_minor = amount_payment_minor`
- Si `payment_currency != base_currency`:
  - obtener tasa `r_pay_to_base` (BUY o MID o MANUAL según 2.3)
  - convertir:
    - `payment_major = minorToMajor(payment_currency, amount_payment_minor)`
    - `base_major = payment_major * r_pay_to_base`
    - `amount_base_minor = majorToMinor(base_currency, base_major, rounding=HALF_UP)`

### 2.4.3 Cálculo de `amount_loan_minor`
- Si `loan_currency == base_currency`:
  - `amount_loan_minor = amount_base_minor`
- Si `loan_currency != base_currency`:
  - obtener tasa `r_loan_to_base` (SELL o MID o MANUAL según 2.3)
  - convertir:
    - `base_major = minorToMajor(base_currency, amount_base_minor)`
    - `loan_major = base_major / r_loan_to_base`
    - `amount_loan_minor = majorToMinor(loan_currency, loan_major, rounding=HALF_UP)`

### 2.4.4 Control de discrepancias por doble redondeo (escenario C)
En scenario C (dos pasos), habrá diferencias por redondeo.
Política:
- guardar `rounding_diff_minor = amount_base_minor - recomputed_base_minor` (si aplica)
- o absorber la diferencia en la última allocation (ver 2.5.5)

---

## 2.5 Distribución (allocations) — coherencia con tu modelo de ciclos

### 2.5.1 Regla general
- **Allocations siempre en LoanCurrency (minor).**
- Los ciclos (`billing_cycles`) y el saldo de capital (`loans.principal_balance`) están en LoanCurrency.

### 2.5.2 Obtener deuda pendiente antes de asignar
Leer:
- `loan.principal_balance` (LoanCurrency)
- ciclos abiertos: `billing_cycles` con `interest_pending > 0` ordenados por `due_date` asc

Convertir todos los valores a minor units para operar (si BD aún usa REAL, convertir a minor en memoria de forma consistente).

### 2.5.3 Orden de aplicación configurable
Usar `app_settings.paymentApplyOrder`.

Definir explícitamente (mínimo):
- Para `MIXED`: `INTEREST -> PRINCIPAL`
- Para `INTEREST`: solo interés
- Para `PRINCIPAL`: solo capital
- Para `CANCEL`: interés pendiente total + capital total (y otros si existen)
- Para `RECOVERY`: capital (cierra sin interés) — si esa es la definición real, documentarla

> Si existen mora, comisiones o penalidades en tu producto, deben entrar en el orden como componentes adicionales.

### 2.5.4 Algoritmo de asignación (detallado)
**Entrada:** `remaining_loan_minor = amount_loan_minor`

#### A) Si declared_type = INTEREST o MIXED (interés primero)
1) Iterar ciclos en orden (más viejo primero):
   - `cycle_interest_pending_minor`
   - `to_pay = min(remaining_loan_minor, cycle_interest_pending_minor)`
   - Crear allocation:
     - `allocation_type = 'INTEREST'`
     - `amount_loan_minor = to_pay`
     - `billing_cycle_id = cycle_id`
   - Actualizar ciclo:
     - `interest_paid += to_pay`
     - `interest_pending -= to_pay`
     - si `interest_pending == 0` marcar ciclo como `PAID` (si corresponde a tu lógica)
   - `remaining_loan_minor -= to_pay`
   - Si `remaining_loan_minor == 0`: terminar

2) Si declared_type = INTEREST: terminar aquí (no tocar capital).

#### B) PRINCIPAL (o MIXED después del interés)
3) Si `remaining_loan_minor > 0`:
   - `principal_to_pay = min(remaining_loan_minor, loan.principal_balance_minor)`
   - Crear allocation:
     - `allocation_type = 'PRINCIPAL'`
     - `amount_loan_minor = principal_to_pay`
     - `billing_cycle_id = NULL` (o ciclo actual si tu negocio lo requiere)
   - Actualizar préstamo:
     - `principal_balance -= principal_to_pay`
   - `remaining_loan_minor -= principal_to_pay`

4) Si `remaining_loan_minor > 0` y ya no hay deuda:
   - Aplicar política de excedente (ver 2.6).

### 2.5.5 Ajuste por redondeo
Si por conversiones y redondeo queda una diferencia de 1–2 minor units:
- absorberla en la última allocation de interés o principal (según `paymentApplyOrder`)
- registrar en `payments.notes` o un campo `rounding_adjustment_minor` si existe

---

## 2.6 Políticas obligatorias para casos límite (no asumir, decidir y documentar)

### 2.6.1 Pago excedente (overpayment)
Definir una sola política (configurable si es necesario):
- **Opción 1:** crear “saldo a favor” del cliente/prestamista (requiere tabla credit_balance).
- **Opción 2:** aplicar a capital (si existe capital pendiente) y el resto marcarlo como `UNAPPLIED`.
- **Opción 3:** bloquear el pago si excede la deuda (no recomendado para UX).

**Debe quedar implementado y probado.**

### 2.6.2 Pago insuficiente en CANCEL
Si declared_type = CANCEL y pago no cubre:
- o se rechaza,
- o se convierte a MIXED automáticamente,
- o se registra como parcial con estado especial.

Decidir y documentar.

### 2.6.3 Tasas faltantes / app offline
Si no se puede obtener tasa y no hay manual:
- bloquear pago.
Si se permite offline:
- usar última tasa conocida y marcar:
  - `fx_status = PENDING_CONFIRMATION`
  - guardar snapshot y permitir “reconfirmar” después (esto implica lógica adicional).

---

## 2.7 Registro en BD (transacción atómica)
En una única transacción:

1) Insert en `payments`:
   - `payment_currency`, `loan_currency`, `amount_payment_minor`, `amount_base_minor`, `amount_loan_minor`
   - snapshot de tasa: `rate_id`, `rate_type_used`, `rate_value_used`, `rate_date_used`
   - `fx_profit_base_minor` y `fx_status`
   - `status='VALID'`

2) Insert en `payment_allocations` (0..N filas):
   - cada allocation con `amount_loan_minor`, tipo, `billing_cycle_id`

3) Update en `billing_cycles` (interés pagado/pendiente, estado)
4) Update en `loans` (`principal_balance`, estado CLOSED si aplica)
5) Si hubo FX: Insert en `payment_fx_details`

6) Commit.

> Si algo falla, rollback completo.

---

## 2.8 Cálculo de diferencial cambiario (FX profit) — fórmula exacta

### 2.8.1 Definir tasa de referencia
Referencia recomendada:
- `reference_rate_value = MID` del mismo snapshot (misma fecha), donde:
  - `mid = (buy_rate + sell_rate)/2`

### 2.8.2 Solo se calcula cuando hay conversión con FX
Caso típico: `payment_currency != base_currency`
- `base_customer_major = payment_major * customer_rate_value`
- `base_reference_major = payment_major * reference_rate_value`

Convertir ambos a minor units de base y:
- `fx_profit_base_minor = base_customer_minor - base_reference_minor`

Interpretación:
- positivo = ganancia por spread
- negativo = pérdida (puede ocurrir con manual o tasas inversas)

Guardar en:
- `payments.fx_profit_base_minor`
- `payment_fx_details.*`

---

## 2.9 Multilenguaje (requisitos concretos)
1) Todos los enums/estados en BD deben ser **códigos**:
   - `VALID`, `VOIDED`, `ACTIVE`, `CLOSED`, `INTEREST`, `PRINCIPAL`, etc.
2) UI resuelve etiquetas por i18n.
3) Reportes deben formatear moneda/fechas con `Intl` usando locale del usuario.
4) Nunca guardar textos “traducidos” en BD.

---

## 2.10 Anulación (VOID) — no editar pagos en caliente
Para auditoría financiera:
- No se “edita” un pago VALID.
- Se anula (VOID) y se revierte su efecto.

### Flujo VOID (atómico):
1) Marcar `payments.status='VOIDED'`, set `void_reason`, `voided_at`.
2) Revertir allocations:
   - por cada allocation original:
     - revertir `billing_cycles.interest_paid/pending`
     - revertir `loans.principal_balance`
3) Marcar FX detail (si existe) como reversado o insertar una fila de reversa.
4) Commit.

---

## 2.11 Pruebas obligatorias (mínimo)
### Unit tests (puro cálculo)
- conversiones por escenarios A/B/C/D
- redondeo por currencies con 0/2/3 decimales
- fx_profit_base_minor correcto con mid vs customer

### Integration tests (BD)
- insertar pago multimoneda → allocations correctas → saldos correctos
- reintento con mismo `idempotency_key` → no duplica
- void → revierte exactamente

### Casos borde
- pago parcial
- pago exacto
- pago excedente
- tasa faltante
- manual rate
- currency sin decimales (JPY)
- valores grandes (overflow)

---

## 3) Checklist de aceptación (Definition of Done)
Un PR se acepta si:
1) Un pago en moneda distinta al préstamo:
   - guarda `amount_payment_minor`, `amount_base_minor`, `amount_loan_minor`
   - guarda snapshot de tasa y (si aplica) fila en `payment_fx_details`
2) La distribución a ciclos y/o capital es correcta y determinística.
3) Reporte de diferencial cambiario se puede calcular con exactitud por pago.
4) No hay floats en cálculos de dinero (o se justifica y se mitiga).
5) Todos los textos son i18n (no hardcode).
6) Casos borde están probados.

---

## 4) Notas finales para el dev
- **No inventar tasas**: si no existe tasa o no se permite manual, el pago se bloquea.
- **No recalcular histórico**: la tasa usada se guarda en el pago.
- **No mezclar monedas en allocations**: allocations siempre en LoanCurrency.
- **Evitar REAL** para dinero: usar minor units.



---

# 5) Ejemplos completos con datos de prueba (para QA y para entender el flujo)

> Todos los ejemplos usan **minor units** (enteros) para dinero.  
> Convención de tasa: **Base per 1 Foreign** (ej. NIO por 1 USD).

## 5.1 Dataset base (monedas + settings)
### 5.1.1 `currencies`
- `NIO` fraction_digits = 2
- `USD` fraction_digits = 2
- `JPY` fraction_digits = 0 (para probar moneda sin decimales)

### 5.1.2 `app_settings` (ejemplo)
- `baseCurrency = NIO`
- `paymentRateType = PROVIDER_BID_ASK`
- `allowManualExchangeRate = true`
- `paymentApplyOrder = INTEREST_THEN_PRINCIPAL`
- `overpaymentPolicy = CREDIT_BALANCE` (definido por el equipo)

> Si tu implementación real usa un objeto settings diferente, mapear estos valores sin cambiar la semántica.

---

## 5.2 Ejemplo 1 — Préstamo en NIO, pago en USD, aplicar a **interés primero** y luego capital

### 5.2.1 Estado inicial (préstamo + ciclos)
**Loan**
- `loan_id = L-001`
- `loan_currency = NIO`
- `principal_balance = 10,000.00 NIO` → `principal_balance_minor = 1_000_000`

**Billing cycles (3 cuotas vencidas)**
1) `cycle_id=C-001`, `due_date=2026-01-01`, `interest_pending = 500.00` → `50_000`
2) `cycle_id=C-002`, `due_date=2026-01-08`, `interest_pending = 500.00` → `50_000`
3) `cycle_id=C-003`, `due_date=2026-01-15`, `interest_pending = 500.00` → `50_000`

### 5.2.2 Tasa del día (USD→NIO)
En `exchange_rates` (base=NIO, foreign=USD, rate_date=2026-01-07):
- `buy_rate = 36.00`
- `sell_rate = 37.00`
- `mid = 36.50`

### 5.2.3 Input del caso de uso
El cliente paga **20.00 USD** hoy:
- `payment_currency = USD`
- `amount_payment_minor = 2_000`
- `declared_type = MIXED`
- `payment_date = 2026-01-07`

### 5.2.4 Conversión esperada
1) Payment→Base (USD→NIO) **usa BUY**:
- `amount_base_major = 20.00 * 36.00 = 720.00 NIO`
- `amount_base_minor = 72_000`

2) Base→Loan (Loan=NIO=Base):
- `amount_loan_minor = 72_000`

### 5.2.5 Distribución (allocations) esperada
Orden: interés vencido por ciclo (más viejo primero), luego capital.

- Paga interés C-001: 50,000 (restan 22,000)
- Interés C-002: 22,000 (queda C-002 con 28,000 pendiente)
- No hay capital porque se consumió en interés

**Allocations esperadas**
1) (payment_id=P-001) `INTEREST`, `cycle=C-001`, `amount_loan_minor=50_000`
2) (payment_id=P-001) `INTEREST`, `cycle=C-002`, `amount_loan_minor=22_000`

### 5.2.6 Registro en `payments` esperado (campos clave)
- `amount_payment_minor = 2_000` (USD)
- `amount_base_minor = 72_000` (NIO)
- `amount_loan_minor = 72_000` (NIO)
- `rate_type_used = BUY`
- `rate_value_used = 36.00`
- `reference_rate_value = 36.50`
- **FX profit** (vs MID):
  - `base_customer = 72_000`
  - `base_reference = 20.00 * 36.50 = 730.00 NIO` → `73_000`
  - `fx_profit_base_minor = 72_000 - 73_000 = -1_000` (pérdida vs MID, porque BUY< MID)

> Nota: Si el negocio define referencia distinta (por ejemplo proveedor_mid distinto), cambiar solo la referencia, no el resto.

---

## 5.3 Ejemplo 2 — Préstamo en USD, pago en NIO (dos monedas, Base=NIO)

### 5.3.1 Estado inicial
- `loan_id=L-002`
- `loan_currency=USD`
- `principal_balance=500.00 USD` → `50_000`
- No hay interés pendiente para simplificar (solo capital).

### 5.3.2 Tasa del día
- buy_rate USD=36.00 (NIO por 1 USD)
- sell_rate USD=37.00

### 5.3.3 Input
Cliente paga **1,000.00 NIO**:
- `payment_currency=NIO`
- `amount_payment_minor=100_000`
- `declared_type=PRINCIPAL`

### 5.3.4 Conversión esperada
1) Payment→Base (ya es base):
- `amount_base_minor=100_000`

2) Base→Loan (NIO→USD) **usa SELL**:
- base_major=1,000.00 NIO
- loan_major = 1,000.00 / 37.00 = 27.027027... USD
- redondeo HALF_UP a 2 decimales:
  - `amount_loan_minor = 2_703` (27.03 USD)

### 5.3.5 Allocations esperadas
- `PRINCIPAL` por 27.03 USD:
  - `principal_balance_minor` baja de 50,000 a 47,297

### 5.3.6 FX profit (si se calcula vs MID)
Referencia MID=36.50:
- base_reference_major for same loan amount depends on approach.
Recomendación: para FX profit en este caso, medir contra “referencia” en la misma dirección:
- customer used SELL=37.00
- reference uses MID=36.50
Como el cliente paga en base y tú conviertes a USD, el “costo FX” para el cliente aumenta con SELL; el diferencial puede considerarse ingreso FX para el prestamista si tu negocio lo define así.  
**Importante:** decidir si FX profit se mide solo cuando el pago está en foreign o también cuando el loan está en foreign. Documentar y mantener consistente.

---

## 5.4 Ejemplo 3 — Escenario C (pago y préstamo son foreign), conversión por 2 pasos

**Base=NIO, Payment=CRC, Loan=USD** (ejemplo para demostrar dos pasos).
- Tasa CRC (base per 1 CRC): buy=0.060, sell=0.062
- Tasa USD: buy=36.00, sell=37.00

Pago: 100,000 CRC (minor=10,000,000 si fraction_digits=2).

Paso 1: CRC→NIO usando BUY CRC  
Paso 2: NIO→USD usando SELL USD  

**Se debe**:
- guardar ambos snapshot (o al menos los valores usados) para auditoría
- manejar diferencia por redondeo:
  - o guardar `rounding_adjustment_minor`
  - o absorber en la última allocation

> Este ejemplo se completa cuando el equipo confirme si CRC está en el catálogo y su fraction_digits.

---

## 5.5 Ejemplo 4 — Moneda sin decimales (JPY) para asegurar robustez
- `JPY` fraction_digits=0
Pago: 1,000 JPY (minor=1,000)
Tasa: buy_rate JPY=0.25 NIO/JPY (ejemplo)

Conversion:
- base_major = 1,000 * 0.25 = 250.00 NIO
- base_minor = 25,000

**Validación:** no se “pierden” unidades por redondeo al pasar JPY minor→major→minor (porque JPY no tiene decimales).

---

## 5.6 Ejemplo 5 — Overpayment (excedente) con política CREDIT_BALANCE
Caso: deuda total en LoanCurrency=50,000 minor, pero `amount_loan_minor=60,000`.

Flujo esperado:
1) Allocations cubren deuda (50,000)
2) Resto (10,000) se registra como:
- `credit_balance` (tabla a crear si no existe), asociado a `client_id` o `loan_id`
- o `payments.unapplied_minor` (si el equipo decide esa estructura)

**No se permite** “crear deuda negativa” en el préstamo.

---

## 5.7 Ejemplo 6 — Tasa manual (allowManualExchangeRate=true)
Pago: 20 USD  
Usuario ingresa manual_rate_value=35.75 (NIO por 1 USD)

Se debe guardar:
- `rate_type_used=MANUAL`
- `rate_value_used=35.75`
- `rate_date_used=2026-01-07`
- `fx_status=APPLIED`

Y aún calcular (opcional) `fx_profit_base_minor` vs referencia (MID proveedor).

---

## 5.8 Ejemplo de inserts (solo guía)
> Los nombres de columnas deben ajustarse a tu migración real.  
> Estos inserts son didácticos; no suponen tu PK real.

```sql
-- Exchange rate snapshot (USD)
INSERT INTO exchange_rates(rate_id, source_currency, target_currency, buy_rate, sell_rate, rate_date)
VALUES ('R-USD-20260107', 'NIO', 'USD', 36.00, 37.00, '2026-01-07');

-- Payment (Ejemplo 1)
INSERT INTO payments(payment_id, loan_id, payment_date, payment_currency, loan_currency,
                     amount_payment_minor, amount_base_minor, amount_loan_minor,
                     rate_id, rate_type_used, rate_value_used, rate_date_used,
                     reference_rate_value, fx_profit_base_minor, status)
VALUES ('P-001', 'L-001', '2026-01-07', 'USD', 'NIO',
        2000, 72000, 72000,
        'R-USD-20260107', 'BUY', 36.00, '2026-01-07',
        36.50, -1000, 'VALID');

-- Allocations (Ejemplo 1)
INSERT INTO payment_allocations(allocation_id, payment_id, billing_cycle_id, allocation_type, amount_loan_minor)
VALUES
('A-001', 'P-001', 'C-001', 'INTEREST', 50000),
('A-002', 'P-001', 'C-002', 'INTEREST', 22000);
```

---

## 5.9 Criterios QA (verificación rápida sobre Ejemplo 1)
- `payments.amount_payment_minor` debe ser 2000 (USD)
- `payments.amount_loan_minor` debe ser 72000 (NIO)
- La suma de allocations debe ser 72000
- `C-001.interest_pending` queda en 0
- `C-002.interest_pending` queda en 28000
- El `principal_balance` del préstamo no cambia (porque todo fue interés)
- `fx_profit_base_minor` coincide con la referencia configurada


---

# 6) Multilenguaje e internacionalización (i18n) — especificación implementable (Flutter)

> Esta sección completa la parte multilenguaje con instrucciones concretas para Flutter.  
> Regla de oro: **la BD guarda códigos/keys estables; la UI traduce**.

## 6.1 Alcance i18n (qué debe ser traducible)
Debe traducirse por i18n (ARB/Intl), sin hardcode:
- Etiquetas de UI (botones, títulos, campos, tabs).
- Mensajes de validación y errores (incluye errores de FX: “falta tasa”, “tasa manual requerida”, etc.).
- Estados del sistema (loan status, payment status, cycle status).
- Tipos de allocation (`INTEREST`, `PRINCIPAL`, etc.).
- Nombres de moneda (display) desde `currencies.name_key`.
- “Formatos” de fecha, hora y números (separadores, orden, etc.).
- Reportes exportados (cabeceras y textos).

## 6.2 Qué NO se traduce en BD (prohibido)
- No guardar textos traducidos en tablas (ej. “Interés”, “Interest”).  
  Guardar el **código** y traducir en app.
- No guardar símbolo/abreviatura como texto “dependiente del idioma” (símbolo `$` es display, pero el nombre debe ir por key).

## 6.3 Estructura recomendada de localización (Flutter)
### 6.3.1 Archivos ARB
- `lib/l10n/app_es.arb`
- `lib/l10n/app_en.arb`
- (si agregan más idiomas: `app_fr.arb`, etc.)

Usar `flutter gen-l10n` o `intl_utils` (una sola vía, consistente).  
**Recomendación:** `flutter gen-l10n` (nativo).

### 6.3.2 Reglas de keys
Keys estables, sin texto quemado en el nombre:
- `payments.title`
- `payments.rateMissing`
- `alloc.interest`
- `alloc.principal`
- `currency.usd`
- `currency.nio`
- `status.payment.valid`
- `status.payment.voided`

Para mensajes con parámetros:
- `payments.fxProfit`: `"FX profit: {amount}"`
- `payments.appliedToCycle`: `"Applied {amount} to cycle {cycle}"`
Acompañar con metadata de parámetros en ARB.

### 6.3.3 Enums → keys (mapping obligatorio)
Crear un mapper central:
- `PaymentStatus.VALID  -> "status.payment.valid"`
- `AllocationType.INTEREST -> "alloc.interest"`
- `FxRateType.BUY -> "fx.rateType.buy"`

Esto evita dispersión de lógica y facilita QA.

## 6.4 Locale del usuario vs moneda base (NO confundir)
- **Locale**: idioma y formato (es_NI, en_US, etc.). Afecta separadores decimales, fecha/hora, etc.
- **BaseCurrency**: moneda funcional de la app (NIO, USD, etc.). Afecta cálculos y consolidación.
- Se permite que un usuario use idioma inglés y moneda base NIO (o viceversa).  
  Por lo tanto:
  - No derivar BaseCurrency del locale automáticamente.
  - Si detectan “país” al inicio, esa detección debe ser un **default**, pero el usuario puede cambiarlo.

## 6.5 Formateo de dinero y números (Intl) — requisitos
### 6.5.1 Mostrar dinero
Usar `NumberFormat.currency` con:
- `locale` actual del usuario
- `name` = ISO code (USD, NIO, etc.)
- `decimalDigits` = `currencies.fraction_digits`

Ejemplo conceptual:
- `formatMoney(minor, currencyCode, locale) -> string`

**Prohibido**: construir strings manuales (ej. `"C$ " + amount`), porque falla con RTL, separadores y decimales.

### 6.5.2 Parseo de inputs monetarios
Inputs del usuario pueden venir con:
- coma decimal (es)
- punto decimal (en)
- separador de miles

Regla: al capturar monto ingresado:
1) Parsear según locale (o normalizar).
2) Convertir a `minor units` usando `fraction_digits` de la moneda seleccionada.
3) Validar que no haya más decimales que `fraction_digits`.

Agregar pruebas para:
- `"1,234.56"` en en_US
- `"1.234,56"` en es_ES/es_NI

## 6.6 Reportes (multilenguaje + multimoneda)
### 6.6.1 ReportCurrency
Los reportes deben:
- Calcular internamente en LoanCurrency/BaseCurrency.
- Convertir a `ReportCurrency` solo para presentación (con tasa del día o tasa fija configurable; no asumir).

### 6.6.2 Cabeceras y textos traducidos
- Cabeceras del reporte: keys en ARB.
- Valores numéricos formateados con locale del usuario.
- Moneda del reporte indicada como ISO.

## 6.7 RTL y tipografías (robustez global)
Si la app es “para todo el mundo”, prepararse para RTL (árabe/hebreo):
- No hardcodear alineación izquierda/derecha; usar `TextAlign.start`, `EdgeInsetsDirectional`.
- Verificar que layouts respondan bien a `Directionality.rtl`.

No es obligatorio lanzar RTL hoy, pero el diseño debe no romperse.

## 6.8 Mensajes de error (i18n) — lista mínima obligatoria para el módulo FX
Estos errores deben existir y traducirse:
- `payments.error.rateNotFound`
- `payments.error.manualRateRequired`
- `payments.error.currencyInactive`
- `payments.error.amountInvalid`
- `payments.error.allocationMismatch` (si suma allocations != amount_loan_minor)
- `payments.error.overpaymentPolicyViolation`

## 6.9 QA i18n (pruebas mínimas)
- Cambiar idioma en runtime y verificar:
  - pantalla de pago (labels, botones, mensajes)
  - formato de moneda (separadores correctos)
  - formato de fecha
- Probar al menos:
  - `es_NI` y `en_US`
- Validar que BD no contiene textos traducidos en columnas críticas (auditar con query).

