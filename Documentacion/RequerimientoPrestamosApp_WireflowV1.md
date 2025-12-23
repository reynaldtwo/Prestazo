# Wireflow V1 (Pantallas + Acciones + Validaciones) – PrestamosApp (Flutter + SQLite Local)

## 0) Alcance de este documento
Define el **flujo de pantallas**, navegación, acciones y validaciones mínimas de la V1.  
No incluye diseño visual (UI kit), ni código.

---

## 1) Navegación principal (Bottom Nav recomendado)
1. **Dashboard**
2. **A Cobrar**
3. **Clientes**
4. **Configuración**

> Nota: Sin login. La app abre directo en Dashboard.

---

## 2) Reglas UX generales (V1)
- Toda operación crítica debe confirmar con diálogo:
  - Crear préstamo
  - Registrar pago
  - Anular pago
  - Restaurar backup
- Mensajes claros y cortos; evitar jerga financiera.
- En listados, soporte de búsqueda rápida por nombre/alias/teléfono.

---

## 3) Pantallas y flujos

### 3.1 Dashboard (Home)
**Objetivo:** ver el estado del negocio hoy/mes.

**Elementos:**
- KPIs del periodo seleccionado (default: mes en curso):
  - Capital colocado (dinero regado)
  - Capital pendiente por recuperar
  - Interés cobrado (mes)
  - Interés pendiente total
  - Clientes en mora (conteo)
- Acciones rápidas:
  - **Registrar pago** (abre selector Cliente → Préstamo)
  - **Nuevo cliente**
  - **Nuevo préstamo** (requiere cliente)

**Navegación:**
- Tap en KPI “Morosos” → listado A Cobrar filtrado “Atrasados”.
- Tap en KPI “Interés pendiente” → A Cobrar “Atrasados”.
- Tap en KPI “Capital colocado” → Clientes (ordenado por saldo desc).

**Validaciones:**
- Si no hay clientes: mostrar CTA “Crear primer cliente”.
- Si hay clientes pero sin préstamos: CTA “Crear primer préstamo”.

---

### 3.2 A Cobrar (Pantalla operativa)
**Objetivo:** listar clientes que deben pagarse en un periodo y permitir registrar pagos rápido.

**Filtros (tabs o dropdown):**
- **Quincena actual**
- **Mes actual**
- **Próximos 7 días**
- **Atrasados**

**Lista (1 fila por cliente, agrupando préstamos):**
- Nombre/alias
- Interés esperado en el periodo
- Interés pendiente total (vencido + actual)
- Saldo capital total (sumatoria préstamos activos)
- Último pago (fecha) y “días desde último pago”
- Indicador: “EN MORA” si aplica

**Acciones por fila:**
- Botón **Registrar pago**
- Tap en fila → Detalle Cliente

**Validaciones / reglas:**
- Si un cliente tiene múltiples préstamos, el botón “Registrar pago” debe pedir elegir el **préstamo** a pagar.
- Si el pago se registra desde “A Cobrar”, preseleccionar:
  - Cliente
  - Periodo actual (para sugerir interés esperado)

---

### 3.3 Clientes (Listado)
**Objetivo:** administrar clientes y entrar a detalle.

**Elementos:**
- Buscador (nombre, alias, teléfono)
- Lista con:
  - Nombre/alias
  - Frecuencia: Quincenal/Mensual
  - Saldo capital total
  - Interés pendiente total
  - Estado: Activo/Inactivo

**Acciones:**
- **Nuevo cliente**
- Tap en cliente → Detalle Cliente

---

### 3.4 Cliente – Detalle / Estado de cuenta consolidado
**Objetivo:** ver estado total del cliente y acceder a préstamos/pagos.

**Secciones:**
1) Resumen:
- Saldo capital total (préstamos activos)
- Interés pendiente total
- Interés cobrado (mes)
- Último pago
- Estado: Activo / En mora (si algún préstamo en mora)

2) Acciones:
- **Nuevo préstamo**
- **Registrar pago**
- **Ver pagos** (historial consolidado)

3) Préstamos del cliente (lista):
- Estado (Activo/Mora/Cerrado)
- Saldo capital
- Tasa mensual
- Próximo vencimiento (DueDate del ciclo más cercano)
- Interés pendiente

**Navegación:**
- Tap préstamo → Detalle Préstamo
- Tap “Registrar pago” → Registro Pago (preselecciona cliente)

**Validaciones:**
- Si cliente Inactivo: permitir ver, pero bloquear “Nuevo préstamo” y “Registrar pago” (configurable; default: bloquear).

---

### 3.5 Préstamo – Detalle
**Objetivo:** ver ciclos, interés, pagos y saldo del préstamo.

**Secciones:**
1) Resumen préstamo:
- Capital original
- Saldo capital actual
- Tasa mensual
- Fecha desembolso
- Estado

2) Ciclos de cobro (lista):
- DueDate
- Interés esperado
- Interés pagado
- Interés pendiente
- Estado (Pendiente/Pagado/Vencido/Cerrado)
- Indicador “Capitalizado” si aplica

3) Pagos (lista):
- Fecha
- Monto
- Estado (Válido/Anulado)
- Tap pago → Detalle pago (solo lectura)

**Acciones:**
- **Registrar pago** (preselecciona préstamo)
- **Anular pago** (desde detalle pago, no desde listado)
- **Generar ciclos** (opción oculta/avanzada si se requiere; default: automático)

---

### 3.6 Registrar Pago (flujo crítico)
**Entrada al flujo:**
- Desde Dashboard (sin selección previa)
- Desde A Cobrar (cliente seleccionado)
- Desde Cliente (cliente seleccionado)
- Desde Préstamo (cliente y préstamo seleccionados)

**Campos:**
- Cliente (selector si no viene preseleccionado)
- Préstamo (selector si no viene preseleccionado)
- Fecha pago (default: hoy; editable)
- Monto (requerido)
- Tipo declarado:
  - Solo interés
  - Solo capital
  - Mixto
- Nota (opcional)
- Vista previa “Aplicación sugerida” (solo lectura):
  - A interés vencido: X
  - A interés actual: Y
  - A capital: Z

**Acciones:**
- Guardar pago → Confirmación → Registrar

**Validaciones:**
- Monto > 0
- Si préstamo cerrado: bloquear registro
- Si pago excede montos pendientes:
  - Permitir, aplicando el excedente a capital (hasta 0) y luego advertir “Excedente no aplicable” (default: **no permitir excedente**; V1 recomendado: **no permitir**).

**Resultado:**
- Genera comprobante interno (ReceiptNumber).
- Actualiza ciclos y saldo.
- Retorna a pantalla origen.

---

### 3.7 Anular Pago (flujo)
**Entrada:** Detalle Pago.

**Campos:**
- Motivo (requerido)

**Reglas:**
- Solo pagos con Status=VALID se pueden anular.
- Anulación recalcula saldos en base a allocations válidas (regla V1).

**Resultado:**
- Marca pago VOIDED + motivo.
- Registra AuditLog + LoanEvent (opcional).

---

### 3.8 Configuración (AppSettings)
**Objetivo:** políticas globales y mantenimiento.

**Secciones:**
1) Políticas:
- Capitalizar interés no pagado (Sí/No)
- Días de tolerancia mora (numérico)
- Orden aplicación pagos (Interés primero / Capital primero)
- Frecuencia por defecto al crear cliente
- Moneda base (NIO)

2) Mantenimiento:
- **Exportar backup**
- **Restaurar backup**
- **Recalcular cartera** (opción avanzada; recomendado mostrarla solo si se detecta inconsistencia)

**Validaciones:**
- MoraDays >= 0
- Confirmación fuerte al restaurar backup (se sobrescribe información).

---

## 4) Flujos mínimos de navegación (resumen)
- Dashboard → Nuevo cliente → Cliente detalle → Nuevo préstamo → Préstamo detalle
- A Cobrar → Registrar pago → Confirmación → Regresa A Cobrar
- Cliente detalle → Registrar pago → Regresa Cliente detalle
- Préstamo detalle → Registrar pago → Regresa Préstamo detalle
- Configuración → Exportar/Restaurar → Confirmación

---

## 5) Criterios de éxito UX V1
- Registrar un pago desde “A Cobrar” en menos de 20 segundos.
- Encontrar un cliente en menos de 5 segundos (búsqueda).
- Identificar morosos en un toque desde Dashboard.
