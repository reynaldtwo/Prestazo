### **Asunto: Refactorización Core Financiero: Lógica Multimoneda Global y Gestión de Tasas Históricas**

Necesitamos evolucionar el sistema de gestión monetaria para que sea un estándar bancario internacional. La implementación debe seguir estos pilares:

#### **1. Entidad de Tasas de Cambio (ExchangeRateTable)**
* Crear un módulo donde el usuario gestione las tasas de cambio por fecha.
* **Campos:** `moneda_origen`, `moneda_destino`, `fecha`, `tasa_compra`, `tasa_venta`.
* Debe permitir carga manual y estar preparado para integración vía API en el futuro.

#### **2. Lógica de "Techo de Capital" (Capital de Trabajo)**
* El **Monto Techo** en Ajustes debe estar ligado obligatoriamente a la **Moneda Base** del sistema. No puede ser un número "huérfano".
* Si el usuario cambia la Moneda Base, el sistema debe ofrecer recalcular el Capital de Trabajo según la tasa vigente.

#### **3. Creación de Préstamos (Business Logic)**
* **Carga Automática:** Al crear un préstamo, el sistema debe buscar en la `ExchangeRateTable` la tasa del día actual y precargarla.
* **Override Parametrizado (Ajustes):** Implementar un "Toggle" en Configuración: *"Permitir modificación manual de tasa en desembolso"*.
    * **Si está OFF:** El campo es solo lectura (tasa oficial).
    * **Si está ON:** El prestamista puede editar la tasa solo para ese contrato.
* **Persistencia:** El préstamo debe guardar la `tasa_aplicada` (Snapshot) de forma permanente para ese contrato.

#### **4. Normalización del Dashboard (La Lógica del Indicador)**
* El indicador de "Capital Colocado" y "Disponible" debe realizar una conversión en tiempo real de toda la cartera a la Moneda Base.
* **Fórmula:** `Disponible = Capital_Trabajo_Base - SUM(Monto_Prestamo * Tasa_Cambio_Actual_o_Contrato)`.
* El Dashboard debe mostrar claramente: **"Total en [Moneda Base]"**.

#### **5. Reporte de Diferencial Cambiario**
* Implementar una lógica que compare el valor del capital activo (en la calle) al momento del desembolso vs. el valor actual según la tasa del día, informando al usuario la ganancia o pérdida por revalorización de divisa.

#### **6. Clean Architecture**
* Aislar la lógica de conversión en un `CurrencyService` o `MoneyManager` para que cualquier parte de la app (reportes, historial, dashboard) pueda obtener valores convertidos de forma consistente.