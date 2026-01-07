# PrestamosApp V1 - Análisis Completo del Proyecto

## 📊 Resumen Ejecutivo

**Tipo de Aplicación:** Sistema de Gestión de Préstamos para prestamistas independientes  
**Framework:** Flutter (Android/Windows)  
**Base de Datos:** SQLite (sqflite)  
**Gestión de Estado:** Riverpod  
**Idiomas:** Español (principal) / Inglés

---

## 🗄️ Base de Datos - Esquema de Tablas

### 1. `customers` - Clientes

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `customer_id` | TEXT PK | UUID único |
| `full_name` | TEXT | Nombre completo |
| `alias` | TEXT? | Apodo/alias |
| `phone` | TEXT? | Teléfono |
| `address` | TEXT? | Dirección |
| `notes` | TEXT? | Notas internas |
| `status` | TEXT | ACTIVE/INACTIVE |
| `billing_frequency` | TEXT | MONTHLY/BIWEEKLY/WEEKLY/DAILY |
| `preferred_pay_day` | INT? | Día preferido de pago |
| `dni` | TEXT? | Documento de identidad |
| `coords` | TEXT? | Coordenadas GPS |
| `is_restricted` | INT | 0/1 - Cliente restringido |
| `restriction_reason` | TEXT? | Motivo de restricción |
| `created_at` | TEXT | Timestamp ISO8601 |
| `updated_at` | TEXT | Timestamp ISO8601 |

---

### 2. `loans` - Préstamos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `loan_id` | TEXT PK | UUID único |
| `customer_id` | TEXT FK | Referencia a cliente |
| `principal_original` | REAL | Capital original |
| `principal_balance` | REAL | Saldo de capital actual |
| `monthly_interest_rate` | REAL | Tasa mensual (%) |
| `rate_unit` | TEXT | MONTHLY |
| `billing_frequency` | TEXT | Frecuencia de cobro |
| `disbursement_date` | TEXT | Fecha de desembolso |
| `end_date` | TEXT? | Fecha fin informativa |
| `status` | TEXT | ACTIVE/OVERDUE/CLOSED |
| `closed_at` | TEXT? | Fecha de cierre |
| `notes` | TEXT? | Notas |
| `loan_number` | TEXT? | Número consecutivo |
| `currency_code` | TEXT | NIO/USD/etc |
| `applied_exchange_rate` | REAL? | Tasa al momento del desembolso |
| `created_at` | TEXT | Timestamp |
| `updated_at` | TEXT | Timestamp |

---

### 3. `billing_cycles` - Ciclos de Facturación

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `billing_cycle_id` | TEXT PK | UUID |
| `loan_id` | TEXT FK | Referencia a préstamo |
| `cycle_number` | INT | Número de ciclo |
| `frequency` | TEXT | Frecuencia |
| `period_start_date` | TEXT | Inicio del período |
| `period_end_date` | TEXT | Fin del período |
| `due_date` | TEXT | Fecha de vencimiento |
| `interest_expected` | REAL | Interés esperado |
| `interest_paid` | REAL | Interés pagado |
| `interest_pending` | REAL | Interés pendiente |
| `status` | TEXT | PENDING/OVERDUE/PAID/CLOSED |
| `closed_at` | TEXT? | Fecha de cierre |
| `is_capitalized` | INT | 0/1 - Capitalizado |
| `capitalized_amount` | REAL | Monto capitalizado |
| `capitalized_at` | TEXT? | Fecha de capitalización |
| `created_at` | TEXT | Timestamp |
| `updated_at` | TEXT | Timestamp |

---

### 4. `payments` - Pagos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `payment_id` | TEXT PK | UUID |
| `loan_id` | TEXT FK | Referencia a préstamo |
| `customer_id` | TEXT FK | Referencia a cliente |
| `payment_date` | TEXT | Fecha del pago |
| `amount` | REAL | Monto pagado |
| `declared_type` | TEXT | MIXED/INTEREST/PRINCIPAL/CANCEL/RECOVERY |
| `receipt_number` | TEXT | Número de recibo |
| `status` | TEXT | VALID/VOIDED |
| `void_reason` | TEXT? | Motivo de anulación |
| `voided_at` | TEXT? | Fecha de anulación |
| `notes` | TEXT? | Notas |
| `payment_currency` | TEXT? | Moneda del pago (si diferente) |
| `exchange_rate_applied` | REAL? | Tasa aplicada |
| `exchange_profit` | REAL? | Ganancia cambiaria |
| `created_at` | TEXT | Timestamp |
| `updated_at` | TEXT | Timestamp |

---

### 5. `payment_allocations` - Distribución de Pagos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `allocation_id` | TEXT PK | UUID |
| `payment_id` | TEXT FK | Referencia a pago |
| `loan_id` | TEXT FK | Referencia a préstamo |
| `allocation_type` | TEXT | INTEREST/PRINCIPAL |
| `amount` | REAL | Monto asignado |
| `billing_cycle_id` | TEXT? | Ciclo relacionado |
| `created_at` | TEXT | Timestamp |

---

### 6. `exchange_rates` - Tasas de Cambio

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `rate_id` | TEXT PK | UUID |
| `source_currency` | TEXT | Moneda origen (USD) |
| `target_currency` | TEXT | Moneda destino (NIO) |
| `rate_date` | TEXT | Fecha de la tasa |
| `buy_rate` | REAL | Tasa de compra |
| `sell_rate` | REAL | Tasa de venta |
| `created_at` | TEXT | Timestamp |

---

### 7. `app_settings` - Configuración Global (1 fila)

| Categoría | Campos Principales |
|-----------|-------------------|
| **Moneda** | `baseCurrency`, `reportCurrency`, `exchangeRate` |
| **Intereses** | `capitalizeUnpaidInterest`, `dailyAccrualEnabled`, `moratoriumDays` |
| **Pagos** | `paymentApplyOrder`, `enableCapitalRestriction`, `capitalRestrictionDays` |
| **DNI** | `validateDni`, `validateDniFormat`, `dniMask` |
| **Empresa** | `companyName`, `companyRuc`, `companyPhone`, `companyLogo`, etc. |
| **Reportes** | `showDisbursementSignatures`, `showPaymentSignatures`, leyendas |
| **Backup** | `backupFrequency`, `backupRetentionDays`, `backupOnPayment` |
| **Tasas** | `disbursementRateType`, `paymentRateType`, `allowManualExchangeRate` |

---

### 8. `audit_logs` - Registros de Auditoría

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `audit_log_id` | TEXT PK | UUID |
| `action` | TEXT | CREATE_CUSTOMER, RECORD_PAYMENT, etc. |
| `entity_type` | TEXT | Customer, Loan, Payment, etc. |
| `entity_id` | TEXT | ID de la entidad afectada |
| `details` | TEXT? | JSON con detalles |
| `created_at` | TEXT | Timestamp |

---

### 9. `loan_events` - Eventos del Préstamo

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `loan_event_id` | TEXT PK | UUID |
| `loan_id` | TEXT FK | Préstamo relacionado |
| `event_type` | TEXT | CAPITALIZATION_APPLIED, STATUS_CHANGED, etc. |
| `related_billing_cycle_id` | TEXT? | Ciclo relacionado |
| `related_payment_id` | TEXT? | Pago relacionado |
| `amount` | REAL? | Monto involucrado |
| `old_value` | TEXT? | Valor anterior |
| `new_value` | TEXT? | Valor nuevo |
| `notes` | TEXT? | Notas |
| `created_at` | TEXT | Timestamp |

---

## 📱 Pantallas del Sistema

### Dashboard (`/dashboard`)
- **Widgets:** Capital disponible, Préstamos activos, Por cobrar hoy, Ganancias
- **Gráficos:** Resumen mensual de ingresos
- **Acciones rápidas:** Nuevo cliente, Nuevo préstamo, Registrar pago

### Clientes (`/customers`)
- **Lista:** Búsqueda, filtros, ordenamiento
- **Formulario:** Todos los campos del cliente
- **Detalle:** Info completa + historial de préstamos

### Préstamos (`/loans`)
- **Lista:** Por estado (activos, vencidos, cerrados)
- **Formulario:** Capital, tasa, frecuencia, fecha desembolso, moneda
- **Detalle:** Ciclos de facturación, historial de pagos, estado actual

### Pagos (`/payments`)
- **Registro:** Selección de cliente/préstamo, monto, tipo de pago
- **Tipos de pago:**
  - MIXED: Distribuido automáticamente
  - INTEREST: Solo interés
  - PRINCIPAL: Solo capital
  - CANCEL: Liquidación total
  - RECOVERY: Recuperación (cierra sin interés)
- **Multi-moneda:** Conversión automática con tasa de cambio

### A Cobrar (`/cobrar`)
- **Vista diaria:** Cuotas que vencen hoy
- **Vista calendario:** Próximos vencimientos
- **Filtros:** Por cliente, estado

### Reportes (`/reports`)
- **Ganancias Reales:** Intereses efectivamente cobrados
- **Proyección:** Intereses esperados de préstamos activos
- **Exportación:** PDF compartible

### Ajustes (`/settings`)
| Sub-pantalla | Funcionalidad |
|--------------|---------------|
| `settings_screen` | Menú principal (77KB - muy grande) |
| `monetary_settings_screen` | Moneda base, capital, tasas |
| `company_settings_screen` | Logo, nombre, datos de empresa |
| `exchange_rate_screen` | Lista de tasas de cambio |
| `exchange_rate_form_screen` | Agregar/editar tasa |
| `report_currency_screen` | Moneda de reportes |
| `scheduled_backup_screen` | Configuración de backups |
| `dni_format_screen` | Formato de DNI por país |
| `country_selection_screen` | Selección de país |
| `currency_selection_screen` | Selector de moneda |
| `about_screen` | Info de la app |

---

## ⚙️ Servicios del Sistema

| Servicio | Archivo | Funcionalidad |
|----------|---------|---------------|
| **InterestCalculationService** | 12KB | Cálculo de intereses, distribución de pagos |
| **BillingCycleService** | 9KB | Generación y gestión de ciclos |
| **PaymentService** | 8KB | Lógica de pagos, cierre de préstamos |
| **PaymentValidationService** | 7KB | Validaciones de pago |
| **CurrencyService** | 13KB | Conversiones, tasas de cambio |
| **BackupService** | 14KB | Backup/restore de base de datos |
| **PDFGeneratorService** | 40KB | Generación de recibos PDF |
| **WhatsAppService** | 7KB | Compartir por WhatsApp |

---

## 📦 Repositorios

| Repositorio | Operaciones |
|-------------|-------------|
| `CustomerRepository` | CRUD clientes |
| `LoanRepository` | CRUD préstamos, cierre, cambio de estado |
| `PaymentRepository` | CRUD pagos, anulación, allocations |
| `BillingCycleRepository` | CRUD ciclos, capitalización |
| `ExchangeRateRepository` | CRUD tasas de cambio |
| `SettingsRepository` | Configuración global |
| `CobrarRepository` | Consultas de "A Cobrar" |

---

## ✅ Funcionalidades Implementadas

- [x] Multi-moneda (préstamos en USD, NIO, etc.)
- [x] Tasas de cambio con compra/venta
- [x] Frecuencias: Mensual, Quincenal, Semanal, Diario
- [x] Interés proporcional (daily accrual)
- [x] Capitalización de intereses no pagados
- [x] Múltiples tipos de pago
- [x] Recibos PDF personalizables
- [x] Compartir por WhatsApp
- [x] Backup automático y manual
- [x] Restricción de clientes (blacklist)
- [x] Auditoría de acciones
- [x] Validación de DNI por país
- [x] Pago en moneda diferente al préstamo
- [x] Navegación con tabs + drawer

---

## ⚠️ Áreas de Mejora Identificadas

1. **settings_screen.dart (77KB)** - Demasiado grande, necesita refactorización
2. **Ganancia cambiaria** - Parcialmente implementada, falta reporte
3. **Validación de tasa de cambio** - Agregada recientemente
4. **Reportes** - Menú con Arc Sidebar recién implementado
5. **Pruebas unitarias** - Cobertura limitada
6. **Respaldo en la nube** - Solo local actualmente

---

## 📐 Arquitectura

```
lib/
├── core/
│   ├── constants/     # AppStatus, AppColors
│   ├── theme/         # AppTheme, AppTypography
│   ├── localization/  # Provider de idioma
│   └── widgets/       # Widgets reutilizables (AppCard, ArcSideBar, etc.)
├── data/
│   ├── models/        # 9 modelos de datos
│   ├── repositories/  # 8 repositorios
│   ├── database/      # DatabaseHelper
│   └── providers/     # Providers de Riverpod
├── services/          # 9 servicios de negocio
├── presentation/
│   ├── screens/       # 7 categorías de pantallas
│   └── widgets/       # Widgets de UI (modales, etc.)
└── l10n/              # Archivos ARB (español/inglés)
```

---

## 🔢 Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| Modelos de datos | 9 |
| Tablas de BD | 9 |
| Pantallas principales | ~25 |
| Servicios | 9 |
| Repositorios | 8 |
| Archivos de localización | 2 (ES, EN) |
| Líneas estimadas | ~20,000+ |

---

*Documento generado: 2026-01-07*
