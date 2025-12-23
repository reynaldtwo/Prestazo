# Contexto_PrestamosApp_V1.md
## Índice maestro de contexto para IA – PrestamosApp (Flutter + SQLite)

### Propósito de este archivo
Este documento sirve como **punto de entrada único** para una IA encargada de desarrollar la aplicación **PrestamosApp V1**.

El objetivo es:
- Evitar ambigüedad.
- Evitar invenciones de reglas.
- Guiar a la IA en el **orden correcto de lectura y ejecución**.

La app es:
- Flutter
- 100% local (offline)
- SQLite embebido
- Sin login
- Orientada a prestamistas informales

---

## 1. Orden obligatorio de lectura

La IA **DEBE** leer los siguientes archivos en este orden:

### 1️⃣ Requerimiento funcional base
**Archivo:** `RequerimientoPrestamosApp.md`

Contiene:
- Objetivo del sistema
- Alcance V1
- Principios del negocio
- Qué hace y qué NO hace la app

➡️ Este archivo define el *qué* del sistema.

---

### 2️⃣ Modelo lógico de base de datos
**Archivo:** `RequerimientoPrestamosApp_ModeloBD.md`

Contiene:
- Entidades principales
- Relaciones
- Conceptos clave (Cliente, Préstamo, Ciclo, Pago)

➡️ Este archivo define el *cómo se estructura la información*.

---

### 3️⃣ Diccionario de datos (SQLite)
**Archivo:** `RequerimientoPrestamosApp_DiccionarioBD.md`

Contiene:
- Tablas
- Campos
- Tipos
- Reglas
- Índices
- Reglas transaccionales

➡️ Este archivo define el *contrato exacto de datos*.

⚠️ Ningún campo ni regla puede ser alterado sin actualizar este documento.

---

### 4️⃣ Reglas de negocio y KPIs (FUENTE DE VERDAD)
**Archivo:** `RequerimientoPrestamosApp_ReglasYKPI_V1.md`

Contiene:
- Reglas deterministas de calendario
- Cálculo de intereses
- Capitalización
- Mora
- Fórmulas exactas de KPIs

➡️ Este archivo es la **FUENTE DE VERDAD** para todo cálculo.

⚠️ Si existe conflicto entre archivos, **este archivo prevalece**.

---

### 5️⃣ Wireflow y UX operativo
**Archivo:** `RequerimientoPrestamosApp_WireflowV1.md`

Contiene:
- Pantallas
- Navegación
- Acciones
- Validaciones
- Flujos críticos (A Cobrar, Registrar Pago)

➡️ Este archivo define *cómo se usa la app en la práctica*.

---

### 6️⃣ Arquitectura Flutter y decisiones técnicas
**Archivo:** `RequerimientoPrestamosApp_ArquitecturaFlutter_V1.md`

Contiene:
- Capas
- Paquetes recomendados
- Migraciones SQLite
- Reglas técnicas mínimas

➡️ Este archivo define *cómo debe construirse el código*.

---

### 7️⃣ Datasets de prueba
**Archivo:** `RequerimientoPrestamosApp_Datasets_V1.md`

Contiene:
- Escenarios reales
- Casos de atraso
- Capitalización ON/OFF
- Anulación de pagos

➡️ Este archivo se usa para **validar que la implementación es correcta**.

---

### 8️⃣ Criterios de aceptación (QA)
**Archivo:** `RequerimientoPrestamosApp_CriteriosAceptacion_V1.md`

Contiene:
- Escenarios Gherkin
- Comportamientos esperados

➡️ Este archivo define *cuándo una funcionalidad está correctamente implementada*.

---

## 2. Reglas obligatorias para la IA

La IA **NO DEBE**:
- Inventar reglas financieras.
- Cambiar fórmulas de interés.
- Cambiar reglas de calendario.
- Editar pagos (solo anular).
- Introducir login o multiusuario.

La IA **DEBE**:
- Respetar cálculos y redondeos.
- Usar transacciones SQLite.
- Implementar primero la pantalla **A Cobrar** y **Registrar Pago**.
- Validar todo con los datasets.

---

## 3. Prioridad de implementación recomendada

1. Inicialización Flutter + SQLite + migraciones
2. AppSettings
3. Clientes
4. Préstamos
5. Generación de ciclos
6. Registrar pago + allocations
7. A Cobrar
8. Reportes / Dashboard
9. Backup y restore
10. Endurecimiento y pruebas

---

## 4. Criterio de éxito V1

La V1 se considera exitosa si:
- El prestamista puede saber en segundos:
  - Cuánto dinero tiene prestado
  - Quién debe pagar hoy
  - Cuánto ha ganado en intereses
- No se pierde información
- Los saldos siempre cuadran
- Los escenarios de prueba pasan sin errores

---

## 5. Nota final para la IA

Este proyecto **no es académico ni bancario**.

Está diseñado para:
- Prestamistas informales
- Operación diaria rápida
- Control mínimo pero confiable

Cualquier sobreingeniería debe evitarse.

