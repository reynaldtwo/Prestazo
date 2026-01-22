# Inventario Detallado de Componentes (BOM) - AppPrestamos

Este documento desglosa los componentes visuales y funcionales de la aplicación a nivel de "Materiales" (Widgets, Textos, Iconos, Lógica UI).

---

## 1. Módulo de Préstamos (Loans)

### 1.1. Pantalla: Formulario de Creación (`LoanFormScreen`)
**Ubicación:** `lib/presentation/screens/loans/loan_form_screen.dart`
**Función:** Creación de nuevos préstamos.

#### A. Cabecera y Cliente
- **AppBar**: Título "Nuevo Préstamo".
- **Info Cliente**: `AppCard`.
    - **Avatar**: `Container` (48x48) con inicial. Color primario/info.
    - **Datos**: Nombre (TitleMedium), Alias (BodySmall).

#### B. Campos de Configuración (Atomic)
| Campo | Icono | Tipo | Detalle Atomic |
| :--- | :--- | :--- | :--- |
| **Plan** | N/A | `DropdownButtonFormField` | Selecciona plantilla. Puede bloquear moneda/tasa. |
| **Moneda** | `Icons.currency_exchange` | `ListTile` Custom | Muestra Símbolo + Código. **Estado Bloqueado**: Icono `lock` y texto "Restringido por Plan". |
| **Tasa Cambio** | `Icons.currency_exchange` | `TextFormField` | Solo visible si moneda difiere de base. **Validación**: Bloquea si no hay tasa del día (`AlertDialog`). |
| **Monto** | Moneda Local | `AppMoneyField` | Input numérico con formateo de miles. |
| **Tasa (%)** | `Icons.percent` | `AppTextField` | Mensual. |
| **Frecuencia** | `Icons.calendar_today` | `InkWell` -> Selector | Abre `PaymentFrequencySelectionScreen`. Muestra intervalo en días. |
| **Desembolso** | `Icons.calendar_today` | `InkWell` -> DatePicker | Fecha inicio. |
| **Vencimiento** | `Icons.event` | `AppTextField` (ReadOnly) | Calculada automáticamente si el plan tiene plazo fijo. |
| **Notas** | `Icons.note` | `AppTextField` | Multilínea (Max 2). |

#### C. Elementos Informativos
- **Cálculo de Interés**: `Container` (Surface Variant). Icono `info_outline`. Muestra "Interés [Frecuencia]: [Monto]".
- **Resumen**: `AppCard` final. Muestra tabla con: Capital, Tasa, Interés estimado por cuota.

#### D. Acciones
- **Botón**: `AppButton` (Primary). Texto "Crear Préstamo". Full Width. Loading State.

### 1.2. Pantalla: Detalle de Préstamo (`LoanDetailScreen`)
**Ubicación:** `lib/presentation/screens/loans/loan_detail_screen.dart`

#### A. Tarjeta de Resumen (`_buildSummaryCard`)
Componente central visualmente denso:
- **Header**: "Préstamo #ID" (TitleMedium Bold) + `StatusBadge`.
- **KPI Principal**: "Capital Original" (`MoneyDisplay` Large).
- **Barra de Herramientas**:
    - `IconButton` (Indigo, `ios_share_rounded`) -> Estado de Cuenta (PDF).
    - `IconButton` (Primary, `receipt_long`) -> Recibo Desembolso.
    - `IconButton` (OnSurface, `edit`) -> Editar (Bloqueado si tiene pagos).
    - `IconButton` (Error, `delete_outline`) -> Borrar (Bloqueado si tiene pagos).
- **Métricas Secundarias (Footer)**:
    - "Saldo Capital": `MoneyLabel`.
    - "Interés Pendiente": `_PendingInterestLabel`.
    - "Tasa": Muestra % y frecuencia (ej: "20.00% Mensual").
    - "Desembolso": Fecha.

#### B. Sección Ciclos (`_BillingCyclesList`)
- **Lista**: Ciclos pendientes/pagados.
- **Item**: Tarjeta con # Ciclo (Color según estado), Fecha Vencimiento, Monto.

#### C. Sección Pagos (`_PaymentsList`)
- **Header**: Título "Historial de Pagos".
- **Item**: Tarjeta con # Recibo, Fecha, Monto total.
- **Acción**: Botón compartir recibo individual.

#### D. Acciones Flotantes/Inferiores
- **Registrar Pago**: `AppButton` (Full Width, Icon `payment`). Solo visible si activo/mora.

#### E. Validaciones Críticas (Modales)
- **Edición**: Bloqueada (`Icons.lock_clock`) si hay pagos > 0.
- **Borrado**: Bloqueado (`Icons.warning_amber`) si hay pagos. Confirmación destructiva (`Icons.delete_forever`) requerida.

---

## 2. Módulo de Clientes (Customers)

### 2.1. Pantalla: Lista de Clientes (`CustomersScreen`)
**Ubicación:** `lib/presentation/screens/customers/customers_screen.dart`
**Función:** Directorio general de clientes con filtrado.

#### A. Barra de Herramientas (AppBar)
- **Título**: "Clientes".
- **Acción**: `IconButton` (`Icons.filter_list`) -> Abre Modal de Filtro.

#### B. Filtros y Búsqueda
- **Búsqueda**: `AppSearchField`. Hint: "Buscar cliente...". Icono: `Icons.search`. (Botón 'X' para limpiar).
- **Contador**: Texto "N Clientes" (BodySmall).
- **Botón Limpiar**: `TextButton.icon` (`Icons.clear`). Aparece solo si hay filtro activo.
- **Modal de Filtro**: BottomSheet con opciones seleccionables (`ListTile` + `Icons.radio_button_checked/unchecked`):
    - Todos, Activos, Inactivos, Quincenal, Mensual.

#### C. Lista de Elementos (`_CustomerListItem`)
Cada cliente es una `AppCard` con degradado opcional (si tiene categoría):
- **Avatar**: `Container` (48x48). Muestra Inicial o Símbolo de Moneda (si tiene préstamo activo).
- **Info Principal**: Nombre (TitleMedium).
- **Badge Frecuencia**: `Container` con texto "15d" o "30d" (LabelSmall).
- **Info Secundaria**: Alias ("Nombre Real") o Teléfono (BodySmall).
- **Acción Rápida**: `IconButton` (`Icons.edit`) -> Navega a Edición.
- **Estado**: `StatusBadge` (Solo si Inactivo).
- **Indicador**: Icono `chevron_right`.

#### D. Acciones Flotantes
- **FAB**: `FloatingActionButton` (`Icons.person_add`). Navega a Registro de Cliente.


### 1.3. Sub-Módulo: Tasas de Cambio (`ExchangeRate`)

#### A. Pantalla: Lista de Tasas (`ExchangeRatesScreen`)
**Ubicación:** `lib/presentation/screens/settings/exchange_rates/exchange_rates_screen.dart`
**Función:** Histórico de tasas.
- **Acción AppBar**: `IconButton` (`Icons.add`) -> Navega a Formulario.
- **Lista**: `ListView.separated` (Divider height 1).
- **Item**: `ListTile`
    - **Titulo**: "1 [Moneda A] = [Compra] / [Venta] [Moneda B]".
    - **Subtítulo**: Fecha formateada (M/d/y) + Hora.
    - **Trailing**: `Icons.chevron_right`.

#### B. Pantalla: Formulario Tasa (`ExchangeRateFormScreen`)
**Ubicación:** `lib/presentation/screens/settings/exchange_rates/exchange_rate_form_screen.dart`

**1. Selector de Monedas (`AppCard`)**
- Estructura: Columna con dos `ListTile` separados por `Divider`.
- **Item Moneda**:
    - **Label**: "Moneda Origen/Destino" (BodySmall).
    - **Valor**: Código Moneda (TitleMedium Bold).
    - **Icono**: `Icons.arrow_forward_ios` (Size 16, Trailing).

**2. Selector de Fecha (`AppCard`)**
- **Widget**: `ListTile`.
- **Título**: "Fecha de Tasa".
- **Subtítulo**: Fecha formateada.
- **Icono**: `Icons.calendar_today` (Color Primary, Trailing).

**3. Inputs de Valores (`Row`)**
- **Compra**: `AppTextField` (Label "Compra", Hint "0.0000").
- **Venta**: `AppTextField` (Label "Venta", Hint "0.0000").
- **Teclado**: Numérico con decimales.

**4. Acciones**
- **Botón**: `AppButton` (Label "Guardar"). Estado Loading.

---

## 2. Módulo de Clientes (Customers)

### 2.1. Pantalla: Lista de Clientes (`CustomersScreen`)
**Ubicación:** `lib/presentation/screens/customers/customers_screen.dart`
**Función:** Directorio general de clientes con filtrado.

#### A. Barra de Herramientas (AppBar)
- **Título**: "Clientes".
- **Acción**: `IconButton` (`Icons.filter_list`) -> Abre Modal de Filtro.

#### B. Filtros y Búsqueda
- **Búsqueda**: `AppSearchField`. Hint: "Buscar cliente...". Icono: `Icons.search`. (Botón 'X' para limpiar).
- **Contador**: Texto "N Clientes" (BodySmall).
- **Botón Limpiar**: `TextButton.icon` (`Icons.clear`). Aparece solo si hay filtro activo.
- **Modal de Filtro**: BottomSheet con opciones seleccionables (`ListTile` + `Icons.radio_button_checked/unchecked`):
    - Todos, Activos, Inactivos, Quincenal, Mensual.

#### C. Lista de Elementos (`_CustomerListItem`)
Cada cliente es una `AppCard` con degradado opcional (si tiene categoría):
- **Avatar**: `Container` (48x48). Muestra Inicial o Símbolo de Moneda (si tiene préstamo activo).
- **Info Principal**: Nombre (TitleMedium).
- **Badge Frecuencia**: `Container` con texto "15d" o "30d" (LabelSmall).
- **Info Secundaria**: Alias ("Nombre Real") o Teléfono (BodySmall).
- **Acción Rápida**: `IconButton` (`Icons.edit`) -> Navega a Edición.
- **Estado**: `StatusBadge` (Solo si Inactivo).
- **Indicador**: Icono `chevron_right`.

#### D. Acciones Flotantes
- **FAB**: `FloatingActionButton` (`Icons.person_add`). Navega a Registro de Cliente.

### 2.2. Pantalla: Detalle de Cliente (`CustomerDetailScreen`)
**Ubicación:** `lib/presentation/screens/customers/customer_detail_screen.dart`

#### A. Header Slivers (`_buildSliverAppBar`)
- **Fondo**: Gradiente Primario.
- **Avatar**: Grande (60x60). Iniciales en blanco.
- **Datos**: Nombre (HeadlineMedium), Estado (Activo/Inactivo), Fecha Registro (`Icons.calendar_today`).
- **Menú Contextual**: `PopupMenuButton`:
    - "Desactivar cliente" (`value: deactivate`).
    - "Ver historial completo" (`value: history`).

#### B. Resumen de Cuenta (`_buildAccountSummary`)
Tarjeta `AppCard` con grid de datos:
1.  **Capital Total**: `_SummaryItem`. Icono `account_balance_wallet`. Valor monetario.
2.  **Interés Mensual**: `_SummaryItem`. Icono `schedule` (Warning Color). Valor monetario.
3.  **Contadores**: Préstamos Cerrados vs Activos (TitleMedium).

#### C. Acciones Rápidas
- **Nuevo Préstamo**: `AppButton` (Primary, `Icons.add_card`).
- **Registrar Pago**: `AppButton` (Secondary, `Icons.payment`).

#### D. Lista de Préstamos (`_LoanCard`)
- **Cabecera**: Título "Préstamos" + Botón "Ver Todos".
- **Tarjeta Préstamo**:
    - **Header**: "Préstamo #ID" + Monto Original (`MoneyDisplay`).
    - **Subtítulo**: Tasa de interés mensual.
    - **Badge**: `StatusBadge` (Activo/Mora/Cerrado).
    - **Cuerpo (Si Activo)**: Row con "Saldo Capital" y "Interés Mensual" (`MoneyLabel`).
    - **Cuerpo (Si Cerrado)**: Fecha de cierre.
- **Acción Deslizar**: `Dismissible` (Fondo Rojo, `Icons.delete`) para borrar préstamos sin pagos.

### 2.3. Pantalla: Formulario de Cliente (`CustomerFormScreen`)
**Ubicación:** `lib/presentation/screens/customers/customer_form_screen.dart`
**Función:** Creación y edición (valida DNI duplicado).

#### A. Campos de Entrada (Atomic)
| Campo | Widget | Icono | Detalle Atomic |
| :--- | :--- | :--- | :--- |
| **Categoría** | `DropdownButtonFormField` | `Icons.category` Prefix | Label: "Category (optional)". Item Style: Standard Text. |
| **Nombre** | `AppTextField` | `Icons.person` | Requerido (Min 2 chars). |
| **DNI** | `AppTextField` | `Icons.badge_outlined` | **Máscara**: `MaskTextInputFormatter`. Validación estricta de formato y duplicados. |
| **Apodo** | `AppTextField` | `Icons.face` | Opcional. |
| **Teléfono** | `AppTextField` | `Icons.phone` | Tipo: Phone. Requerido. |
| **Dirección** | `AppTextField` | `Icons.location_on` | MaxLines 2. Requerido. |
| **Coordenadas** | `AppTextField` | `Icons.pin_drop` | Label: "PIN". Opcional. |
| **Día Pago** | `AppTextField` | `Icons.calendar_today` | Tipo: Number. Rango 1-31. |
| **Notas** | `AppTextField` | `Icons.note` | MaxLines 3. |

#### B. Sección Restricciones (Solo Edición)
- **Contenedor**: `Container` con borde y fondo rojo tenue (`AppColors.danger`).
- **Checkbox**: `Checkbox` + Texto "Marcar cliente como NO PRESTAR" (Bold, Rojo).
- **Motivo**: `AppTextField` visible solo si activado. Icono `warning_amber`.

#### C. Acciones
- **Botón**: `AppButton` (Primary). Texto: "Crear Cliente" / "Guardar".
- **Validación Manual**: `SnackBar` (Rojo) para errores de formato específico (DNI).
- **Alerta Duplicado**: `AlertDialog` (`Icons.warning_amber` Rojo). Muestra datos del cliente existente.

---

## 3. Módulo de Cobranza (Collection)


### 3.1. Pantalla: Gestión de Cobros (`CobrarScreen`)
**Ubicación:** `lib/presentation/screens/cobrar/cobrar_screen.dart`
**Función:** Tablero operativo para gestionar cobros pendientes y vencidos.

#### A. Estructura Principal
- **Tabs**: `TabBar` con 2 pestanas: "Por Cobrar" (Próximos) y "Vencidos" (Mora).
- **Buscador**: `TextField` con decoración estándar y botón "Clear".
- **Empty States**: `AppEmptyState` específico para cada tab (Icono `receipt_long` vs `check_circle`).

#### B. Tarjeta de Cobro (`_CustomerDueCard`)
Componente complejo que resume la deuda del cliente:
1.  **Avatar de Estado**:
    -   Normal: Fondo Primary/Info.
    -   Mora: Fondo Rojo (Error) + Texto Rojo.
2.  **Identificadores**:
    -   Nombre Cliente + Alias.
    -   `StatusBadge` (Solo si está en mora).
    -   Lista de préstamos activos (ej: "Préstamo #101, #103").
3.  **Fechas Dinámicas**:
    -   Si Tab="Por Cobrar": Muestra "Vence el: [Fecha]".
    -   Si Tab="Vencidos": Muestra "Vencido desde: [Fecha]" (Color Rojo).
4.  **Métricas Financieras (`MoneyLabel`)**:
    -   "Cuota": Monto a pagar.
    -   "Interés Esperado" / "Pendiente".
    -   "Capital": Saldo actual.
5.  **Indicadores de Alerta**:
    -   **Días Mora**: Pill Container rojo "X días de atraso".
    -   **Multi-Préstamo**: Pill Container azul "X Préstamos Activos".
6.  **Acción Principal**: Botón `AppButton` (Variant: Secondary) "Registrar Pago".

### 3.2. Pantalla: Formulario de Pago (`PaymentFormScreen`)
**Ubicación:** `lib/presentation/screens/payments/payment_form_screen.dart`
**Función:** Registro de transacciones con soporte multi-moneda.

#### A. Selectores de Entidad
- **Cliente**: Lista con `ListTile` + Avatar. Al seleccionar, se transforma en `AppCard` compacto con botón cerrar.
- **Préstamo**: Lista mostrando saldo y tasa.

#### B. Lógica Monetaria (`_buildPaymentCurrencySelector` + Inputs)
- **Moneda de Pago**: Chips o Dropdown para elegir moneda de recepción (ej: Córdoba vs Dólar).
- **Tasa de Cambio**: `AppTextField` visible solo si la moneda de pago difiere de la del préstamo.
- **Monto**:
    -   `AppTextField` numérico.
    -   **Calculadora Integrada**: `IconButton` (`Icons.calculate_outlined`) abre `CurrencyCalculatorModal`.

#### C. Tipos de Pago (`ChoiceChip`)
- **Opciones**: "Mixto" (Estándar), "Solo Interés", "Abono Capital", "Cancelación", "Recuperación".
- **Lógica UI**: Deshabilita ciertos tipos si el préstamo es "Nivelado" (Cuota Fija), forzando el modo estándar o cancelación.

#### D. Previsualización y Confirmación
- **Allocation Preview**: Tarjeta que muestra en tiempo real cómo se distribuye el dinero (Mora -> Interés -> Capital).
- **Notas**: Campo opcional.
- **Submit**: Botón con estado de carga (`_isLoading`).

---

## 3. Módulo Dashboard (Inicio)

### 4.1. Pantalla: Dashboard (`DashboardScreen`)
**Ubicación:** `lib/presentation/screens/dashboard/dashboard_screen.dart`
**Función:** Resumen ejecutivo y control de mando principal.

#### A. Header Dinámico (`_buildHeader`)
- **Saludo**: Ajusta texto según la hora ("Buenos días/tardes/noches").
- **Título**: Muestra nombre de la empresa si está configurado.

#### B. Acciones Rápidas (Accesos Directos)
- **Registrar Pago**: `AppButton` (Secondary) -> `PaymentFormScreen`.
- **Nuevo Cliente**: `AppButton` (Outline) -> `CustomerFormScreen`.

#### C. Grid de KPIs (Indicadores Clave)
1.  **Capital Colocado (Card Full Width):**
    -   **Visual**: Custom Animated Progress Bar (Calcula % uso capital).
    -   **Color**: Semáforo (Verde < 50%, Naranja < 75%, Rojo > 90%).
2.  **Ganancias Mes (Card Full Width):**
    -   `MoneyDisplay` Grande. Icono `trending_up` (Success).
3.  **Matriz 2x2**:
    -   **Proyección**: Icono `show_chart` (Info).
    -   **Vencidos**: Icono `warning_amber`. Texto **ROJO** si > 0.
    -   **Activos**: Conteo de Préstamos y Clientes.

#### D. Resumen de Hoy (`_buildTodaySummary`)
- Tarjeta operativa para el cierre de caja diario.
- Comparativa: "Capital Recuperado" vs "Total Recaudado".
- Contador de recibos generados.

#### E. Accesos Rápidos (Lista Inferior)
- Diseño tipo `ListTile` estilizado dentro de `AppCard`.
- Navegación a: Ruta de Cobro, Historial de Pagos, Directorio de Clientes.

---

## 4. Componentes Compartidos (Core Widgets)
Estos son los bloques de construcción base utilizados en casi todas las pantallas anteriores.

| Widget | Archivo | Descripción Visual |
| :--- | :--- | :--- |
| `AppCard` | `app_card.dart` | `Card` con elevación suave, `borderRadius: 12`, color de superficie adaptativo. Usado para agrupar cualquier dato. |
| `AppButton` | `app_button.dart` | Botón estandarizado. Variantes: `primary` (Filled), `secondary` (Tonal), `outline`, `ghost`. Soporta estado `isLoading`. |
| `AppTextField` | `app_text_field.dart` | `TextFormField` con decoración `OutlineInputBorder`, soporte para iconos prefijos/sufijos y validación integrada. |
| `MoneyDisplay` | `money_display.dart` | `Row` que formatea montos: Símbolo pequeño + Monto grande + Decimales pequeños. Soporta colores positivos/negativos. |
| `StatusBadge` | `status_badge.dart` | `Container` tipo "Pill" con color de fondo y texto basado en `AppStatus` (Active=Verde, Late=Rojo, Closed=Gris). |
| `AppDialogs` | `app_dialogs.dart` | Utilidad estática para invocar alertas consistentes (Confirmar borrado, Errores). |

---

## 5. Módulo de Reportes

### 5.1. Pantalla: Reporte Diferencial (`CurrencyDifferentialReportScreen`)
*   **Gráfico:** Barras/Líneas comparando Moneda Base vs Moneda Secundaria.
*   **Tabla:** Lista de transacciones con desglose de TC (Tasa Cambio).

### 5.2. Pantalla: Reporte FX (`FxDifferentialReportScreen`)
*   **KPIs:** Ganancia/Pérdida por diferencial cambiario.
*   **Filtros:** Por rango de fechas.

---

## 6. Módulo de Ajustes (Settings)

### 6.1. Pantalla Principal (`SettingsScreen`)
**Ubicación:** `lib/presentation/screens/settings/settings_screen.dart`
**Función:** Menú principal de configuración.

#### A. Tarjetas de Menú
| Icono | Título | Subtítulo | Navegación |
| :--- | :--- | :--- | :--- |
| `Icons.business` | Datos de la Empresa | Configurar nombre, logo y dirección | `/settings/company` |
| `Icons.category` | Catálogo | Categorías, Frecuencias, Planes | `/settings/customer-categories` |
| `Icons.monetization_on` | Gestión Monetaria | Monedas, Tasa de Cambio | `monetary-settings` |
| `Icons.calculate_outlined` | Políticas del Negocio | Convención, Interés, Mora | `FinancialPolicyScreen` |
| `Icons.format_list_numbered` | Secuencias | Numeración de Préstamos/Recibos | (Local) |
| `Icons.description` | Reportes | Firmas y Leyendas | (Local) |
| `Icons.backup` | Mantenimiento | Copias de Seguridad | (Local) |
| `Icons.palette` | Apariencia | Tema Claro/Oscuro | (Local) |
| `Icons.info_outline` | Acerca de | Versión de App | (Local) |

### 6.2. Pantalla: Datos de la Empresa (`CompanySettingsScreen`)
**Ubicación:** `lib/presentation/screens/settings/company_settings_screen.dart`

#### A. Header Informativo
- **Componente**: `Container` (Color Info/10%).
- **Icono**: `Icons.info_outline` (Info Color).
- **Texto**: "La información configurada aquí aparecerá en los encabezados de reportes y recibos PDF."

#### B. Campos de Configuración (Atomic)
| Label | Icono | Tipo | Detalle |
| :--- | :--- | :--- | :--- |
| **País de Operación** | `Icons.public` | `AppTextField` (ReadOnly) | Abre selector de país. Muestra bandera emoji. |
| **Nombre de la Empresa** | `Icons.business` | `AppTextField` + `Switch` | Toggle "Visible/Oculto". |
| **RUC / Identificación** | `Icons.confirmation_number` | `AppTextField` + `Switch` | Toggle "Visible/Oculto". |
| **Teléfono Fijo** | `Icons.phone` | `AppTextField` + `Switch` | Toggle "Visible/Oculto". |
| **Celular / Móvil** | `Icons.smartphone` | `AppTextField` + `Switch` | Toggle "Visible/Oculto". |
| **WhatsApp** | `Icons.chat` | `AppTextField` + `Switch` | Toggle "Visible/Oculto". |
| **Dirección** | `Icons.location_on` | `AppTextField` (MaxLines 2) + `Switch` | Toggle "Visible/Oculto". |
| **Ruta del Logo** | `Icons.image` | `AppTextField` + `IconButton` (`folder_open`) | Selector de archivos .png. Toggle "Visible/Oculto". |

#### C. Acciones
- **Botón**: `AppButton` (Full Width). Texto: "Guardar Cambios". Estado de Carga: `CircularProgressIndicator`.

### 6.3. Pantalla: Políticas Financieras (`FinancialPolicyScreen`)
**Ubicación:** `lib/presentation/screens/settings/financial_policy_screen.dart`

#### A. Header Informativo
- **Card**: `Icons.info_outline`. Texto explicativo sobre cálculo de intereses.

#### B. Formulario de Cálculo
| Campo | Tipo | Opciones / Validación |
| :--- | :--- | :--- |
| **Convención de Conteo** | `DropdownButtonFormField` | 30/360, Actual/360, Actual/365, 30/365. |
| **Días por Mes** | `TextFormField` | Numérico (1-31). Autocompletado segun convención. |
| **Días por Año** | `TextFormField` | Numérico (360-366). Autocompletado segun convención. |
| **Regla de Prorrateo** | `DropdownButtonFormField` | Días Exactos vs Proporción del Ciclo. |
| **Decimales** | `DropdownButtonFormField` | 2, 3, 4. |
| **Modo Redondeo** | `DropdownButtonFormField` | Medio Arriba, Bancario, Truncar, Arriba. |

#### C. Vista Previa (`Card` PrimaryContainer)
- **Header**: Icono `Icons.calculate` + Título "Vista Previa del Cálculo".
- **Datos**: Capital, Tasa Mensual, Días, Tasa Diaria.
- **Resultado**: "Interés Calculado: C$ X.XX" (Headline Style).

#### D. Acciones
- **Botón**: `ElevatedButton.icon`. Label: "Guardar Configuración". Icono: `Icons.save`.

---

Este inventario cubre la totalidad de la estructura visual y funcional actual de la aplicación v1.0.
