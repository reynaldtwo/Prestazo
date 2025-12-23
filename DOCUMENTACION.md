# PrestamosApp - Documentación Completa

## 📱 Descripción General

PrestamosApp es una aplicación de gestión de préstamos diseñada para prestamistas locales en Nicaragua. Permite administrar clientes, préstamos, cobros de intereses y pagos.

---

## 🗃️ Base de Datos

### Tablas Principales

| Tabla | Descripción |
|-------|-------------|
| `customers` | Clientes registrados |
| `loans` | Préstamos activos y cerrados |
| `billing_cycles` | Ciclos de cobro de interés (quincenal/mensual) |
| `payments` | Pagos recibidos |
| `payment_allocations` | Distribución de cada pago (interés/capital) |
| `app_settings` | Configuración de la app |

### Estructura de Tablas

#### customers
```sql
customer_id       TEXT PRIMARY KEY
full_name         TEXT NOT NULL
alias             TEXT (apodo/nombre corto)
phone             TEXT
address           TEXT
billing_frequency TEXT ('MONTHLY' | 'BIWEEKLY')
status            TEXT ('ACTIVE' | 'INACTIVE')
created_at        TEXT (fecha de registro)
updated_at        TEXT
```

#### loans
```sql
loan_id               TEXT PRIMARY KEY
customer_id           TEXT (→ customers)
principal_original    REAL (monto original prestado)
principal_balance     REAL (saldo de capital pendiente)
monthly_interest_rate REAL (tasa mensual, ej: 0.20 = 20%)
rate_unit             TEXT ('MONTHLY')
disbursement_date     TEXT (fecha de desembolso)
status                TEXT ('ACTIVE' | 'CLOSED' | 'IN_MORA')
closed_at             TEXT
notes                 TEXT
created_at            TEXT
updated_at            TEXT
```

#### billing_cycles
```sql
billing_cycle_id   TEXT PRIMARY KEY
loan_id            TEXT (→ loans)
cycle_number       INTEGER (1, 2, 3...)
frequency          TEXT ('MONTHLY' | 'BIWEEKLY')
period_start_date  TEXT
period_end_date    TEXT
due_date           TEXT (fecha de vencimiento)
interest_expected  REAL (interés esperado del ciclo)
interest_paid      REAL (interés ya cobrado)
interest_pending   REAL (interés pendiente = expected - paid)
status             TEXT ('PENDING' | 'PARTIAL' | 'PAID' | 'OVERDUE')
created_at         TEXT
updated_at         TEXT
```

#### payments
```sql
payment_id     TEXT PRIMARY KEY
loan_id        TEXT (→ loans)
customer_id    TEXT (→ customers)
payment_date   TEXT
amount         REAL (monto total del pago)
declared_type  TEXT ('MIXED' | 'INTEREST' | 'PRINCIPAL')
receipt_number INTEGER
notes          TEXT
status         TEXT ('VALID' | 'VOIDED')
created_at     TEXT
updated_at     TEXT
```

#### payment_allocations
```sql
allocation_id    TEXT PRIMARY KEY
payment_id       TEXT (→ payments)
loan_id          TEXT (→ loans)
allocation_type  TEXT ('INTEREST' | 'PRINCIPAL')
amount           REAL
billing_cycle_id TEXT (→ billing_cycles, si es INTEREST)
created_at       TEXT
```

---

## 📱 Pantallas

### 1. Dashboard (Inicio)
- Muestra estadísticas: total capital, interés pendiente, clientes en mora
- Acciones rápidas: Nuevo Cliente, Nuevo Préstamo, Registrar Pago, Historial de Pagos
- Resumen de actividad del día

### 2. A Cobrar
- Lista clientes con pagos pendientes
- Filtros: Quincenal, Mensual, Próximos 7 días, En Mora
- Muestra días de atraso y monto pendiente
- Botón "Registrar Pago" en cada tarjeta

### 3. Clientes
- Lista todos los clientes activos
- Búsqueda por nombre/alias
- Botón para crear nuevo cliente
- Click en cliente → ver detalle

### 4. Detalle de Cliente
- Información: nombre, teléfono, frecuencia, fecha de registro
- Resumen de cuenta: capital total, interés mensual
- Lista de préstamos activos y cerrados
- Botones: Editar cliente, Nuevo préstamo

### 5. Formulario de Cliente
- Campos: Nombre completo, Alias, Teléfono, Dirección
- Frecuencia de cobro: Mensual (30 días) o Quincenal (15 días)

### 6. Formulario de Préstamo
- Muestra info del cliente
- Campos: Monto del capital, Tasa de interés mensual (%), Fecha de desembolso
- Calcula y muestra el interés mensual/quincenal esperado

### 7. Detalle de Préstamo
- Capital original y saldo
- Tasa de interés
- Historial de pagos del préstamo
- Estado (Activo/Cerrado)

### 8. Registrar Pago
- Selección de cliente y préstamo
- Monto del pago
- Tipo: Mixto, Solo Interés, Solo Capital
- Vista previa de aplicación (a interés vencido, interés actual, capital)

### 9. Historial de Pagos
- Lista todos los pagos registrados
- Muestra: cliente, fecha, monto, distribución interés/capital

### 10. Configuración
- Ajustes de la aplicación

---

## 🔄 Flujo de Operación

### Flujo Completo de un Préstamo

```
1. CREAR CLIENTE
   └─> Se guarda en tabla 'customers'
   └─> Se asigna frecuencia de cobro (MONTHLY/BIWEEKLY)

2. CREAR PRÉSTAMO
   └─> Se guarda en tabla 'loans' con status='ACTIVE'
   └─> Se CREA AUTOMÁTICAMENTE el primer 'billing_cycle':
       - due_date = disbursement_date + 30 días (mensual) o + 15 días (quincenal)
       - interest_expected = capital × tasa_mensual (o ÷2 si quincenal)
       - interest_pending = interest_expected
       - status = 'PENDING'

3. PANTALLA "A COBRAR"
   └─> Muestra clientes que tienen billing_cycles con status='PENDING' o 'PARTIAL'
   └─> Si due_date < hoy, se muestra como "atrasado" con días de mora
   └─> IMPORTANTE: Solo aparecen clientes con billing_cycles pendientes

4. REGISTRAR PAGO
   └─> Se crea registro en 'payments'
   └─> Se crean 'payment_allocations' distribuyendo:
       1° A interés vencido (billing_cycles con due_date < hoy)
       2° A interés actual (billing_cycles con due_date >= hoy)
       3° A capital (si sobra y el tipo lo permite)
   └─> Se actualiza interest_paid e interest_pending en billing_cycles
   └─> Se actualiza principal_balance en loans (si hubo pago a capital)

5. CICLO SE COMPLETA
   └─> Cuando interest_pending = 0, el billing_cycle pasa a status='PAID'
   └─> SE DEBE CREAR MANUALMENTE el siguiente ciclo (o implementar automatización)

6. PRÉSTAMO SE CIERRA
   └─> Cuando principal_balance = 0, se cierra el préstamo
   └─> status='CLOSED', closed_at=fecha
```

---

## 🧪 Guía de Pruebas

### Prueba 1: Flujo Básico Completo

1. **Crear Cliente**
   - Ir a Clientes → Nuevo Cliente
   - Nombre: "Juan Pérez Test"
   - Alias: "Juanito"
   - Frecuencia: Mensual
   - Guardar

2. **Crear Préstamo**
   - Ir al detalle del cliente → Nuevo Préstamo
   - Monto: 10,000
   - Tasa: 20%
   - Fecha de desembolso: **HACE 35 DÍAS** (para que aparezca en mora)
   - Guardar

3. **Verificar en "A Cobrar"**
   - Ir a pestaña "A Cobrar"
   - El cliente debe aparecer como "En Mora" con ~5 días de atraso
   - Interés pendiente debe mostrar: C$ 2,000.00 (10,000 × 20%)

4. **Registrar Pago**
   - Click en "Registrar Pago" del cliente
   - Monto: 2,500
   - Tipo: Mixto
   - La app debe mostrar distribución:
     - A interés vencido: C$ 2,000.00
     - A capital: C$ 500.00

5. **Verificar Resultado**
   - En detalle del cliente:
     - Capital debe ser: C$ 9,500.00 (original - 500)
   - En "Historial de Pagos":
     - Debe aparecer el pago con Interés: 2,000 y Capital: 500

### Prueba 2: Cliente Quincenal

1. Crear cliente con frecuencia "Quincenal"
2. Crear préstamo de C$ 5,000 al 20% con fecha de hace 20 días
3. Debe aparecer en "A Cobrar" con:
   - Interés esperado: C$ 500.00 (5,000 × 20% ÷ 2 para quincenal)
   - Días de atraso: ~5 días

### Verificación del Formato de Números

- Los montos deben mostrarse como: `C$ 10,000.00`
- Separador de miles: coma (,)
- Separador de decimales: punto (.)

---

## ⚠️ Notas Importantes

1. **Billing Cycles**: Los clientes SOLO aparecen en "A Cobrar" si tienen billing_cycles con estado PENDING o PARTIAL. Al crear un préstamo, se crea automáticamente el primer ciclo.

2. **Fecha de Desembolso**: Para probar clientes "en mora", la fecha de desembolso debe ser anterior a hoy - días de la frecuencia (30 o 15).

3. **Próximos Ciclos**: Actualmente el sistema NO crea automáticamente ciclos futuros. Esto es una mejora pendiente.

4. **Moneda**: Todo está en Córdobas Nicaragüenses (C$).

---

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── theme/           # Colores, tipografía
│   └── widgets/         # Widgets reutilizables (MoneyDisplay, AppCard, etc)
├── data/
│   ├── database/        # SQLite helper
│   ├── models/          # Customer, Loan, Payment, BillingCycle
│   ├── providers/       # Riverpod providers
│   └── repositories/    # Acceso a BD
├── presentation/
│   ├── screens/         # Pantallas de la app
│   ├── router.dart      # Navegación con GoRouter
│   └── shell_screen.dart # Bottom navigation
└── main.dart
```

---

## 🔧 Tecnologías

- **Flutter** 3.x
- **Riverpod** - Estado
- **SQLite** (sqflite) - Base de datos local
- **GoRouter** - Navegación
- **Equatable** - Modelos inmutables
