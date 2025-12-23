# Escenarios de Prueba - PrestamosApp 🧪

Este documento detalla paso a paso cómo probar la aplicación asegurando resultados precisos.

> **FECHA DE PRUEBA ACTUAL**: 17 de Diciembre 2025
> **REGLA DE ORO**: Para que un cliente salga "Atrasado", la fecha de vencimiento debe ser ANTERIOR a hoy.
> - **Mensual**: Vence 30 días después del desembolso.
> - **Quincenal**: Vence 15 días después del desembolso.

---

## 🟢 Escenario 1: Probar Cliente "Atrasado" (Mensual)

**Objetivo**: Verificar que un cliente con cuota vencida aparece en "A Cobrar" y desaparece al pagar.

### 1. Configuración del Préstamo
Para que esté **atrasado hoy (17 Dic)**, el préstamo debió vencer antes del 16 Dic.
Como es mensual (+30 días), debemos crearlo con fecha anterior al **16 Nov**.

- **Cliente**: "Juan Atrasado"
- **Frecuencia**: Mensual
- **Monto**: C$ 10,000
- **Tasa**: 20% mensual
- **Fecha Desembolso**: **01 de Noviembre 2025**
  - *Cálculo*: 01 Nov + 30 días = Vence el **01 de Diciembre**.
  - *Estado*: Hoy es 17 Dic, así que tiene **16 días de atraso**.

### 2. Pasos de Prueba
1. **Crear Cliente**: Nombre "Juan Atrasado", Frecuencia "Mensual".
2. **Crear Préstamo**:
   - Monto: `10000`
   - Tasa: `20`
   - Fecha Desembolso: `01/11/2025` (Hace 46 días)
3. **Ir a "A Cobrar"**:
   - Seleccionar filtro "En Mora" (o ver lista general).
   - **✅ Resultado Esperado**:
     - Cliente: Juan Atrasado
     - Días Atraso: **16 días** (aprox)
     - Interés Pendiente: **C$ 2,000.00**

### 3. Prueba de Pago
1. Click en "Registrar Pago".
2. Monto: `2000` (Solo cubrir intereses).
3. Tipo: "Solo Interés".
4. Confirmar.
   - **✅ Resultado Esperado**: Me nsaje de éxito.
5. Volver a "A Cobrar".
   - **✅ Resultado Esperado**: El cliente **YA NO APARECE** en la lista (porque ya pagó la mora).

---

## 🟡 Escenario 2: Probar Cliente "Próximo a Vencer" (Quincenal)

**Objetivo**: Verificar un cliente que NO está atrasado, pero pagará antes de tiempo.

### 1. Configuración del Préstamo
Queremos que venza en 3 días (20 Dic).
Como es quincenal (+15 días), fecha desembolso = 20 Dic - 15 días = 05 Dic.

- **Cliente**: "Maria Quincenal"
- **Frecuencia**: Quincenal
- **Monto**: C$ 5,000
- **Tasa**: 20% mensual (10% quincenal)
- **Fecha Desembolso**: **05 de Diciembre 2025**
  - *Cálculo*: 05 Dic + 15 días = Vence el **20 de Diciembre**.
  - *Estado*: Hoy es 17 Dic, faltan **3 días** para vencer.

### 2. Pasos de Prueba
1. **Crear Cliente**: Nombre "Maria Quincenal", Frecuencia "Quincenal".
2. **Crear Préstamo**:
   - Monto: `5000`
   - Tasa: `20`
   - Fecha Desembolso: `05/12/2025`
3. **Ir a "A Cobrar"**:
   - Este cliente **NO** saldrá en filtro "En Mora".
   - Usar filtro **"Próximos 7 días"**.
   - **✅ Resultado Esperado**:
     - Cliente: Maria Quincenal
     - Días Atraso: 0 (o indicación de fecha futura)
     - Interés Pendiente: **C$ 500.00** (5000 * 10%)

---

## 🔵 Escenario 3: Probar Pago a Capital (Abono Extra)

**Objetivo**: Verificar que el capital baja correctamente.

### 1. Configuración
Usaremos el mismo cliente "Maria Quincenal" del paso anterior. Deuda actual: Capital 5,000 + Interés 500 = 5,500 total para limpiar ciclo.
Pagaremos 1,500 córdobas. (500 interés + 1,000 capital).

### 2. Pasos de Prueba
1. Ir a "Registrar Pago" (desde A Cobrar o desde Detalle Cliente).
2. Monto: `1500`.
3. Tipo: "Mixto" (o dejar por defecto).
   - Ver "Aplicación del Pago":
     - A Interés: C$ 500.00
     - A Capital: C$ 1,000.00
4. Confirmar Pago.
5. **Ir a Detalle del Cliente**:
   - Ver sección de Préstamo Activo.
   - **✅ Resultado Esperado**:
     - Capital Original: C$ 5,000.00
     - Saldo Capital: **C$ 4,000.00** (bajó 1,000)

---

## 🟣 Escenario 4: Validación de Dashboard

**Objetivo**: Verificar que los números globales cuadren.

1. **Ir al Inicio (Dashboard)**.
2. Revisar Tarjetas Superiores:
   - **Cartera Activa (Saldo Capital)**: Debe ser la suma de los saldos capitales (Juan 10,000 + Maria 4,000 = **14,000**).
   - **Interés Pendiente**: Como Juan ya pagó y Maria no ha pagado todo (o si ya pagó en escenario 3), debería reflejar solo lo pendiente real.
   - **Clientes en Mora**: Debería ser **0** (porque Juan ya pagó su mora).

---

## 📋 Resumen de Fechas para Pruebas (Referencia Hoy 17 Dic)

| Tipo Prueba | Frecuencia | Fecha Desembolso Sugerida | Fecha Vencimiento Resultante | Estado Esperado Hoy |
|---|---|---|---|---|
| **Mora Alta** | Mensual | **01 Nov 2025** | 01 Dic 2025 | 🔴 Vencido hace 16 días |
| **Mora Baja** | Quincenal | **25 Nov 2025** | 10 Dic 2025 | 🔴 Vencido hace 7 días |
| **Al Día** | Mensual | **01 Dic 2025** | 31 Dic 2025 | 🟢 Faltan 14 días |
| **Al Día** | Quincenal | **10 Dic 2025** | 25 Dic 2025 | 🟢 Faltan 8 días |

---

## 🛠️ Notas Técnicas para el Tester

1. **Limpieza**: Si deseas reiniciar pruebas, desinstala el App y vuelve a instalar el APK.
2. **Billing Cycles**: Recuerda, el sistema crea AUTOMÁTICAMENTE el primer ciclo (cuota 1) al crear el préstamo. No necesitas crearlo manual.
3. **Refrescar**: Si algo no actualiza visualmente al instante, prueba deslizar hacia abajo (pull-to-refresh) o usar el botón de recarga en la barra superior.
