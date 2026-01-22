# Documentación de Colores - Modo Oscuro (Nocturne Emerald)

Este documento detalla la paleta de colores y estilos aplicados a los componentes de la interfaz de usuario cuando el **Modo Oscuro** (Nocturne Emerald) está activo.

## 🎨 Paleta Base (Nocturne Emerald)

| Token | Color Hex | Descripción |
| :--- | :--- | :--- |
| **Background** | `#0B0F14` | Fondo principal de las pantallas (Scaffold). |
| **Surface** | `#121826` | Fondo para tarjetas, diálogos y appbars. |
| **Surface Elevated** | `#182235` | Fondo para tarjetas "elevadas" o destacadas. |
| **Surface Variant** | `#1F2A44` | Fondo secundario (chips, inputs, bordes suaves). |
| **Primary** | `#2D7DFF` | Color principal para acciones (Azul vibrante). |
| **Secondary / Accent** | `#18D6B4` | Color de acento (Verde esmeralda/dinero). |
| **Error** | `#FF4D6D` | Color para errores y estados críticos. |

---

## 🧩 Componentes UI

### 1. Textos (Typography)

| Elemento | Color Hex | Token |
| :--- | :--- | :--- |
| **Principal** (Títulos, Cuerpo) | `#EAF0FF` | `textPrimaryDark` |
| **Secundario** (Subtítulos, Etiquetas) | `#B7C3DE` | `textSecondaryDark` |
| **Terciario** (Hints, Placeholders) | `#7F8FB3` | `textTertiaryDark` |
| **Sobre Primario** | `#FFFFFF` | `textOnPrimary` |

### 2. Botones (Buttons)

#### ElevatedButton (Primary Action)
*   **Fondo**: `#2D7DFF` (`primaryDarkTheme`)
*   **Texto/Icono**: `#FFFFFF` (`textOnPrimary`)
*   **Forma**: Borde redondeado (8px).

#### FloatingActionButton (FAB)
*   **Fondo**: `#18D6B4` (`secondaryDarkTheme`)
*   **Icono**: `#062019` (`onSecondaryDarkTheme`)

---

### 3. Entradas de Datos (Inputs / TextFields)

| Parte del Input | Color Hex | Token |
| :--- | :--- | :--- |
| **Fondo (Relleno)** | `#1F2A44` | `surfaceVariantDark` |
| **Texto Escrito** | `#EAF0FF` | `textPrimaryDark` |
| **Label (Inactivo)** | `#B7C3DE` | `textSecondaryDark` |
| **Hint (Sugerencia)** | `#7F8FB3` | `textTertiaryDark` |
| **Borde (Reposo)** | `#2C3A5A` | `borderDark` |
| **Borde (Foco)** | `#2D7DFF` | `primaryDarkTheme` |

---

### 4. Contenedores y Estructura

#### AppBar (Barra Superior)
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Texto/Iconos**: `#EAF0FF` (`textPrimaryDark`)

#### Cards (Tarjetas)
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Borde**: `#2C3A5A` (`borderDark`)

#### Bottom Navigation Bar
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Ítem Seleccionado**: `#2D7DFF` (`primaryDarkTheme`)
*   **Ítem Inactivo**: `#7F8FB3` (`textTertiaryDark`)

---

### 5. Bordes y Divisores

| Elemento | Color Hex | Token |
| :--- | :--- | :--- |
| **Divider (Separador)** | `#22304A` | `dividerDark` |
| **Borde Estándar** | `#2C3A5A` | `borderDark` |

---

### 6. Chips y Selectores

#### ChoiceChip (Tipos de Pago, Filtros)
*   **Fondo (No Seleccionado)**: `#1F2A44` (`surfaceVariantDark`)
*   **Fondo (Seleccionado)**: `#2D7DFF` con alpha 0.2 (`primaryDarkTheme`)
*   **Texto (No Seleccionado)**: `#B7C3DE` (`textSecondaryDark`)
*   **Texto (Seleccionado)**: `#2D7DFF` (`primaryDarkTheme`)
*   **Variante Success (Ej: Cancelar)**: `#22C55E` con alpha 0.2 (`successDark`)
*   **Variante Info (Ej: Recuperación)**: `#38BDF8` con alpha 0.2 (`infoDark`)

#### SegmentedButton (Selector Tema, Idioma)
*   **Fondo Contenedor**: `#182235` (`surfaceElevatedDark`)
*   **Fondo Seleccionado**: `#2D7DFF` (`primaryDarkTheme`)
*   **Texto Seleccionado**: `#FFFFFF` (`textOnPrimary`)
*   **Texto No Seleccionado**: `#EAF0FF` (`textPrimaryDark`)
*   **Borde Redondeado**: 28-32px

#### DropdownButtonFormField
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Texto Valor**: `#EAF0FF` (`textPrimaryDark`)
*   **Label**: `#B7C3DE` (`textSecondaryDark`)
*   **Icono Flecha**: `#7F8FB3` (`iconInactiveDark`)
*   **Borde**: `#2C3A5A` (`borderDark`)

---

### 7. Iconos y Estados Semánticos

| Contexto | Icono Ejemplo | Color Hex | Token |
| :--- | :--- | :--- | :--- |
| **Primario/Acción** | `calendar_today`, `edit` | `#2D7DFF` | `primaryDarkTheme` |
| **Información** | `info_outline`, `currency_exchange` | `#38BDF8` | `infoDark` |
| **Éxito/Confirmar** | `check_circle`, `payment` | `#22C55E` | `successDark` |
| **Advertencia** | `warning_amber`, `schedule` | `#FFB020` | `warningDark` |
| **Error/Peligro** | `delete_forever`, `delete_outline` | `#FF4D6D` | `errorDark` |
| **Inactivo/Neutral** | `chevron_right`, `lock` | `#7F8FB3` | `iconInactiveDark` |
| **Sobre Superficie** | `close`, `arrow_back` | `#EAF0FF` | `textPrimaryDark` |

---

### 8. ListTile y Elementos de Lista

#### ListTile Estándar
*   **Fondo**: Transparente (hereda del padre)
*   **Título**: `#EAF0FF` (`textPrimaryDark`)
*   **Subtítulo**: `#B7C3DE` (`textSecondaryDark`)
*   **Leading Icon**: Depende del contexto semántico (ver sección 7)
*   **Trailing Icon**: `#7F8FB3` (`iconInactiveDark`) - típicamente `chevron_right`

#### RadioListTile (Opciones de Selección)
*   **Radio No Seleccionado**: `#7F8FB3` (`iconInactiveDark`)
*   **Radio Seleccionado**: `#2D7DFF` (`primaryDarkTheme`)
*   **Texto**: `#EAF0FF` (`textPrimaryDark`)

#### Checkbox
*   **Borde (No Marcado)**: `#7F8FB3` (`iconInactiveDark`)
*   **Fondo (Marcado)**: `#2D7DFF` (`primaryDarkTheme`)
*   **Check Icon**: `#FFFFFF` (`textOnPrimary`)

---

### 9. Avatares y Contenedores Circulares

#### CircleAvatar (Cliente, Iniciales)
*   **Fondo Normal**: `#38BDF8` con alpha 0.1 (`infoDark`)
*   **Texto Inicial**: `#38BDF8` (`infoDark`)
*   **Fondo Alternativo (Primary)**: `#2D7DFF` con alpha 0.1
*   **Texto Alternativo**: `#2D7DFF` (`primaryDarkTheme`)

#### Avatar de Estado (Mora/Normal)
*   **Fondo Normal**: `#38BDF8` con alpha 0.1 (`infoDark`)
*   **Fondo Mora**: `#FF4D6D` con alpha 0.1 (`errorDark`)
*   **Texto Mora**: `#FF4D6D` (`errorDark`)

---

### 10. Diálogos y Modales

#### AlertDialog
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Título**: `#EAF0FF` (`textPrimaryDark`)
*   **Contenido**: `#B7C3DE` (`textSecondaryDark`)
*   **Botón Primary**: Fondo `#2D7DFF`, Texto `#FFFFFF`
*   **Botón Danger**: Fondo `#FF4D6D`, Texto `#FFFFFF`
*   **Botón Warning**: Fondo `#FFB020`, Texto contraste

#### SimpleDialog / SimpleDialogOption
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Título**: `#EAF0FF` (`textPrimaryDark`)
*   **Opción Hover**: `#1F2A44` (`surfaceVariantDark`)

#### BottomSheet / ModalBottomSheet
*   **Fondo**: `#121826` (`surfaceDark`)
*   **Handle**: `#2C3A5A` (`borderDark`)
*   **Título**: `#EAF0FF` (`textPrimaryDark`)

---

### 11. Indicadores de Progreso

#### CircularProgressIndicator
*   **Color**: `#2D7DFF` (`primaryDarkTheme`)
*   **Track (Opcional)**: `#1F2A44` (`surfaceVariantDark`)

#### LinearProgressIndicator
*   **Color**: `#2D7DFF` (`primaryDarkTheme`)
*   **Track**: `#1F2A44` (`surfaceVariantDark`)

---

### 12. Selectores de Fecha y Moneda

#### DatePicker Container (InkWell + Container)
*   **Fondo**: Transparente
*   **Borde**: `#2C3A5A` (`borderDark`)
*   **Borde Variante**: `outlineVariant` del tema
*   **Icono Calendar**: `#7F8FB3` o `#2D7DFF` según estado
*   **Texto Fecha**: `#EAF0FF` (`textPrimaryDark`)
*   **Label**: `#B7C3DE` (`textSecondaryDark`)
*   **Icono Edit (Trailing)**: `#7F8FB3` (`iconInactiveDark`)

#### Selector de Moneda (ListTile Custom)
*   **Símbolo Moneda**: `#2D7DFF` (`primaryDarkTheme`) o `#B7C3DE` si bloqueado
*   **Nombre Moneda**: `#EAF0FF` (`textPrimaryDark`)
*   **Subtítulo (Moneda Base)**: `#B7C3DE` (`textSecondaryDark`)
*   **Icono `lock_outline`**: `#7F8FB3` (`iconInactiveDark`)
*   **Icono `chevron_right`**: `#7F8FB3` (`iconInactiveDark`)
*   **Estado Bloqueado**: Opacity 0.7

#### Campo Tasa de Cambio
*   **Icono `currency_exchange`**: `#38BDF8` (`infoDark`) o `#2D7DFF` (`primaryDarkTheme`)
*   **Texto Editable**: `#2D7DFF` (`primaryDarkTheme`)
*   **Texto Info**: `#38BDF8` (`infoDark`)
*   **Loading Indicator**: `CircularProgressIndicator` pequeño

---

### 13. Snackbar y Notificaciones

| Estado | Fondo | Token |
| :--- | :--- | :--- |
| **Success** | `#22C55E` | `successDark` |
| **Warning** | `#FFB020` | `warningDark` |
| **Error** | `#FF4D6D` | `errorDark` |
| **Info** | `#38BDF8` | `infoDark` |

*   **Texto**: `#FFFFFF` (contraste sobre todos los fondos)

---

### 14. Badges y Pills

#### StatusBadge (Estado de Préstamo)
| Estado | Fondo | Texto | Token Fondo |
| :--- | :--- | :--- | :--- |
| **Activo** | `#22C55E` alpha 0.15 | `#22C55E` | `successDark` |
| **Mora** | `#FF4D6D` alpha 0.15 | `#FF4D6D` | `errorDark` |
| **Cerrado** | `#7F8FB3` alpha 0.15 | `#7F8FB3` | `iconInactiveDark` |
| **Pendiente** | `#FFB020` alpha 0.15 | `#FFB020` | `warningDark` |

#### Pill Indicadores (Días Mora, Multi-Préstamo)
*   **Pill Rojo (Mora)**: Fondo `#FF4D6D` alpha 0.15, Texto `#FF4D6D`
*   **Pill Azul (Info)**: Fondo `#38BDF8` alpha 0.15, Texto `#38BDF8`

---

### 15. TabBar

*   **Fondo**: `#121826` (`surfaceDark`)
*   **Tab Seleccionado**: `#2D7DFF` (`primaryDarkTheme`)
*   **Tab Inactivo**: `#7F8FB3` (`textTertiaryDark`)
*   **Indicador**: `#2D7DFF` (`primaryDarkTheme`)

---

### 16. Pantalla "Acerca de" (AboutScreen)

> ⚠️ **ATENCIÓN**: Esta pantalla usa colores hardcodeados que deben adaptarse al modo oscuro.

#### Logo Container (Círculo con Sombra)
*   **Fondo Actual**: `Colors.white` ❌ (Hardcoded)
*   **Fondo Modo Oscuro**: `#182235` (`surfaceElevatedDark`)
*   **Sombra**: `Colors.black` alpha 0.1 ❌ → Usar `#000000` alpha 0.3 en oscuro
*   **BoxShadow Blur**: 10px

#### Título App "Prestazo"
*   **Color Actual**: `AppColors.primary` ❌ (No adaptativo)
*   **Color Modo Oscuro**: `#2D7DFF` (`primaryDarkTheme`)

#### Versión / Copyright
*   **Color Actual**: `AppColors.textSecondary` ❌ (No adaptativo)
*   **Color Modo Oscuro**: `#B7C3DE` (`textSecondaryDark`)

#### Feature Items (Iconos + Texto)
*   **Icono Color Actual**: `AppColors.primary` ❌
*   **Icono Modo Oscuro**: `#2D7DFF` (`primaryDarkTheme`)
*   **Texto**: `#EAF0FF` (`textPrimaryDark`)

---

### 17. Switch / Toggle

*   **Track Inactivo**: `#2C3A5A` (`borderDark`)
*   **Track Activo**: `#2D7DFF` con alpha 0.5 (`primaryDarkTheme`)
*   **Thumb Inactivo**: `#7F8FB3` (`iconInactiveDark`)
*   **Thumb Activo**: `#2D7DFF` (`primaryDarkTheme`)

---

### 18. Tooltip

*   **Fondo**: `#1F2A44` (`surfaceVariantDark`)
*   **Texto**: `#EAF0FF` (`textPrimaryDark`)

---

## 📋 Auditoría de Pantallas (30 Pantallas Revisadas)

### ✅ Pantallas Bien Adaptadas
Las siguientes pantallas usan correctamente `Theme.of(context).brightness == Brightness.dark`:

| Pantalla | Archivo |
|----------|---------|
| Dashboard | `dashboard_screen.dart` |
| Cobrar | `cobrar_screen.dart` |
| Reportes | `reports_screen.dart` |
| Loan Form | `loan_form_screen.dart` |
| Payment Form | `payment_form_screen.dart` |
| Settings | `settings_screen.dart` |
| Loan Detail | `loan_detail_screen.dart` (parcialmente) |

---

### ⚠️ Pantallas con Colores Hardcodeados (REQUIEREN CORRECCIÓN)

#### 1. `customer_detail_screen.dart`

| Línea | Problema | Color Hardcodeado |
|-------|----------|-------------------|
| 103 | SliverAppBar backgroundColor | `AppColors.primary` |
| 106 | FlexibleSpaceBar gradient | `AppColors.primaryGradient` |
| 119 | Avatar container | `Colors.white.withValues(alpha: 0.2)` |
| 125-129 | Texto sobre gradient | `Colors.white`, `Colors.white70` |
| 159-163 | Icono y texto | `Colors.white70` |

**Corrección sugerida**:
- Usar `Theme.of(context).colorScheme.primary` o tokens oscuros
- Avatar en dark: `#182235` con alpha
- Texto en dark: `#EAF0FF`

---

#### 2. `about_screen.dart`

| Línea | Problema | Color Hardcodeado |
|-------|----------|-------------------|
| 27-28 | Logo container | `Colors.white`, `Colors.black` shadow |
| 43-44 | Título app | `AppColors.primary` |
| 51-53 | Versión | `AppColors.textSecondary` |
| 100 | Copyright | `AppColors.textSecondary` |
| 114 | Feature items iconos | `AppColors.primary` |

**Corrección sugerida**:
- Logo container dark: `#182235` (`surfaceElevatedDark`)
- Título dark: `#2D7DFF` (`primaryDarkTheme`)
- Texto secundario dark: `#B7C3DE` (`textSecondaryDark`)

---

#### 3. `monetary_settings_screen.dart`

| Línea | Problema | Color Hardcodeado |
|-------|----------|-------------------|
| 63 | Scaffold backgroundColor | `AppColors.background` |
| 75 | AppBar subtitle | `AppColors.textSecondary` |
| 160 | Icono monetization | `AppColors.textSecondary` |
| 205 | Icono save | `AppColors.primary` |
| 229 | Texto descripción | `AppColors.textSecondary` |
| 334 | Icono currency_exchange | `AppColors.accent` |
| 345 | Icono edit_note | `AppColors.info` |
| 512-514 | Section header | `AppColors.primary` |
| 615 | Icono warning | `AppColors.warning` |

**Corrección**: Usar `Theme.of(context).brightness == Brightness.dark` para seleccionar tokens.

---

#### 4. `loan_detail_screen.dart`

| Línea | Problema | Color Hardcodeado |
|-------|----------|-------------------|
| 203 | Snackbar error | `AppColors.danger` (sin isDark) |
| 652 | IconButton color | `Colors.indigoAccent` |
| 656 | IconButton background | `Colors.indigoAccent.withValues(alpha: 0.1)` |

**Corrección sugerida**:
- Línea 203: Usar `Theme.of(context).colorScheme.error`
- Línea 652-656: Reemplazar `Colors.indigoAccent` con token temático

---

### 🔧 Patrón de Corrección Recomendado

Para corregir colores hardcodeados, usar este patrón:

```dart
// ❌ Incorrecto
color: AppColors.primary

// ✅ Correcto
color: Theme.of(context).brightness == Brightness.dark
    ? AppColors.primaryDarkTheme
    : AppColors.primary
```

O mejor, usar los tokens del `ColorScheme`:

```dart
// ✅ Óptimo (respeta el tema automáticamente)
color: Theme.of(context).colorScheme.primary
```
