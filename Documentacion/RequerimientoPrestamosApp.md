# Requerimiento V1 – App de Control de Préstamos Informales (Offline)

## 1. Objetivo del proyecto
Desarrollar una aplicación **100% local (offline)**, con base de datos **SQLite embebida**, destinada a prestamistas informales en Nicaragua.  
La app debe permitir llevar un **control mínimo, claro y confiable** del negocio de préstamos, sin complejidad financiera innecesaria.

La V1 está orientada a:
- Controlar clientes y préstamos.
- Calcular intereses simples.
- Registrar pagos flexibles.
- Identificar clientes a cobrar por quincena o mes.
- Visualizar resultados básicos del negocio.

No es un sistema financiero formal ni bancario.

---

## 2. Alcance de la V1
Incluye:
- Clientes.
- Préstamos.
- Intereses por ciclo (quincenal o mensual).
- Pagos (interés, capital o mixtos).
- Mora simple.
- Reportes básicos.
- Configuración general del negocio.

No incluye:
- Garantías o colaterales.
- Facturación fiscal.
- Integraciones bancarias o pasarelas de pago.
- Sincronización entre dispositivos.
- Cuotas fijas tipo amortización bancaria.

---

## 3. Principios de diseño
- **Offline-first:** todo funciona sin internet.
- **Simplicidad:** reflejar la realidad del prestamista informal.
- **Trazabilidad:** ningún pago se pierde ni se edita sin rastro.
- **Configurabilidad:** reglas de negocio ajustables desde la app.
- **Velocidad operativa:** registrar un pago en segundos.

---

## 4. Arquitectura general
- Aplicación local (móvil o escritorio).
- Base de datos SQLite embebida.
- Lógica de negocio en la app.
- Exportación/backup a archivo.

No existe backend ni API en V1.

---

## 5. Configuración global (Pantalla de Políticas)
Pantalla obligatoria para definir reglas generales del negocio.

Configuraciones mínimas:
- Moneda principal (NIO).
- Tasa quincenal derivada: **Mensual / 2** (regla fija).
- Días de tolerancia para mora (ej. 7 días).
- Regla de aplicación de pagos:
  - Interés primero (default).
  - Capital primero (opcional).
- **Capitalizar interés no pagado:** Sí / No.
- Numeración interna de comprobantes.
- Frecuencia por defecto al crear clientes.

Estas reglas aplican a todos los préstamos nuevos.

---

## 6. Módulo de Clientes

### Datos del cliente
- Nombre completo.
- Apodo / Alias.
- Teléfono.
- Dirección o referencia.
- Nota libre.

### Configuración por cliente
- Frecuencia de cobro:
  - Quincenal
  - Mensual
- Día preferido de cobro (opcional).
- Estado: Activo / Inactivo.

### Funcionalidades
- Crear / editar cliente.
- Ver estado de cuenta consolidado.
- Ver préstamos activos e históricos.

---

## 7. Módulo de Préstamos

### Creación de préstamo
Datos requeridos:
- Cliente.
- Monto del préstamo (capital).
- Tasa de interés mensual (%).
- Fecha de desembolso.
- Nota.

### Reglas clave
- Un cliente puede tener **varios préstamos activos**.
- No existe plazo obligatorio.
- El préstamo permanece activo mientras exista saldo.
- El interés se calcula sobre **saldo de capital**.

### Estados del préstamo
- Activo.
- En mora.
- Cancelado (saldo = 0).

---

## 8. Ciclos de cobro (concepto central)

### Definición
La app genera **ciclos de cobro** según la frecuencia del cliente:
- Quincenal: cada 15 días.
- Mensual: cada 30 días / fin de mes.

### Por cada ciclo se registra:
- Fecha inicio.
- Fecha fin / vencimiento.
- Interés esperado.
- Interés pagado.
- Interés pendiente.
- Estado: Pendiente / Pagado / Vencido.

### Capitalización de intereses
Según configuración global:
- **NO:** el interés pendiente queda como deuda de interés.
- **SÍ:** al vencer el ciclo, el interés pendiente se suma al capital.

---

## 9. Módulo de Pagos

### Registro de pago
Datos:
- Cliente.
- Préstamo.
- Fecha.
- Monto.
- Tipo:
  - Solo interés.
  - Abono a capital.
  - Mixto.
- Nota opcional.

### Aplicación automática del pago
Por defecto:
1. Interés vencido.
2. Interés del ciclo actual.
3. Capital.

### Reglas importantes
- Los pagos **no se editan**.
- Solo se permite **anulación** con motivo.
- Cada pago genera comprobante interno.

---

## 10. Mora

### Regla de mora
Un préstamo entra en mora si:
- Pasa más de X días (configurable) sin pagar el interés esperado del ciclo.

### Funcionalidades
- Listado de clientes en mora.
- Días de atraso.
- Interés pendiente.
- Último pago registrado.

---

## 11. Pantalla “A Cobrar” (operativa clave)

Pantalla principal para el prestamista.

Filtros:
- Quincena actual.
- Mes actual.
- Próximos días.
- Atrasados.

Listado muestra:
- Cliente (una sola vez, agrupando préstamos).
- Interés esperado del periodo.
- Interés pendiente.
- Saldo total de capital.
- Último pago.
- Acción rápida: Registrar pago.

---

## 12. Reportes V1

### Dashboard general
- Capital colocado (dinero regado).
- Capital pendiente por recuperar.
- Interés cobrado en el periodo.
- Interés pendiente total.
- Clientes en mora.

### Reportes por cliente
- Total prestado histórico.
- Total capital abonado.
- Total interés cobrado.
- Saldo actual.
- Historial de pagos.

---

## 13. Seguridad
- Acceso por PIN o contraseña.
- Bloqueo por intentos fallidos.
- Auditoría de pagos y anulaciones.
- Base de datos protegida por el sistema operativo.

---

## 14. Backup y recuperación
- Exportación manual de la base de datos.
- Backup automático antes de migraciones.
- Restauración desde archivo.

---

## 15. Modelo de datos (alto nivel)

Entidades principales:
- AppSettings
- Customer
- Loan
- BillingCycle
- Payment
- PaymentAllocation
- AuditLog

Reglas:
- Saldos nunca negativos.
- Redondeo consistente a 2 decimales.
- Integridad referencial.

---

## 16. Alcance futuro (fuera de V1)
- Sincronización entre dispositivos.
- Exportación avanzada (Excel).
- Recordatorios automáticos.
- Gestión de garantías.
- Multiusuario con roles avanzados.

---

## 17. Criterio de éxito de la V1
La V1 se considera exitosa si:
- El prestamista puede saber en segundos:
  - Cuánto dinero tiene prestado.
  - Quién le debe pagar hoy.
  - Cuánto ha ganado en intereses.
- Puede registrar pagos sin errores.
- No pierde información.
