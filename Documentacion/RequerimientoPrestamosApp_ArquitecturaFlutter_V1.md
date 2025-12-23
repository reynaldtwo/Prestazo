# Arquitectura y Decisiones Técnicas V1 (Flutter + SQLite Embebido)

## 1) Objetivo
Definir decisiones técnicas mínimas para que una IA implemente la app sin desviarse del requerimiento.

---

## 2) Estructura de capas (recomendada)
- **Presentation (UI):** pantallas + widgets + navegación.
- **State Management:** controlador de estado por feature.
- **Domain:** casos de uso (crear préstamo, generar ciclos, registrar pago, anular pago, capitalizar).
- **Data:** repositorios SQLite + mappers.

---

## 3) Paquetes recomendados (decisión V1)
SQLite / persistencia (elegir uno):
- Opción A (simple): `sqflite` + `path_provider`
- Opción B (más robusta): `drift` (ORM + migraciones) + `sqlite3_flutter_libs`

Recomendación V1: **Drift** si el equipo quiere migraciones seguras; si no, `sqflite`.

Estado:
- `riverpod` (recomendado por claridad y testabilidad) o `flutter_bloc`.

Navegación:
- `go_router` (opcional) o Navigator 2.0 básico.

Fechas:
- `intl` para formateo.

Backup/restore:
- `file_picker` (para elegir ubicación) y `share_plus` (para compartir backup), si aplica.

---

## 4) Migraciones de BD (obligatorio V1)
- Mantener `schema_version`.
- Antes de migrar, ejecutar backup automático.
- Migraciones forward-only.

---

## 5) Servicio de “Recalcular cartera” (mantenimiento)
Por robustez:
- Recalcular `Loan.PrincipalBalance` desde allocations PRINCIPAL válidas.
- Recalcular `BillingCycle.InterestPaid/Pending` desde allocations INTEREST válidas.
- Recalcular Status (Loan y cycles).

Esta función ayuda a corregir inconsistencias sin soporte técnico avanzado.

---

## 6) Política de seguridad (sin login)
- Sin login significa sin control de acceso.
- Recomendación V1.1: “Bloqueo local por PIN” (no cuenta como login de usuario, sino como protección del dispositivo).
