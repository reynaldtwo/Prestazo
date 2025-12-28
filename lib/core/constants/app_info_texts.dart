/// Centralized storage for long informational/help texts
/// This allows for easier maintenance and potential future localization
class AppInfoTexts {
  /// Explanation for "Capital disponible para prestar" setting
  static String availableCapitalTitle(bool isSpanish) => isSpanish
      ? 'Proyección de Capital y Límites'
      : 'Capital Projection & Limits';

  static String availableCapitalDescription(bool isSpanish) => isSpanish
      ? '''
El "Capital disponible para prestar" funciona como un límite de seguridad y una herramienta de planificación financiera para tu negocio de préstamos.

**¿Para qué sirve?**
Este valor establece un techo máximo para el capital total que puedes tener prestado (en la calle) en un momento dado. No es una cuenta bancaria real, sino un límite administrativo que defines tú mismo.

**¿Qué pasa si lo activo?**
Cuando la opción "Validar capital de trabajo" está activada, antes de crear un nuevo préstamo, el sistema verificará si tienes saldo disponible suficiente.

1. **Cálculo:** Se resta la suma de todos los capitales prestados activos de este límite global.
2. **Validación:** Si el nuevo préstamo excede el remanente, el sistema te avisará e impedirá la creación del préstamo para evitar sobregiros no planificados.

**Recomendación:**
Mantén este valor actualizado según tu capacidad real de inversión o el presupuesto que has asignado para tu cartera de créditos. Si tu negocio crece, recuerda aumentar este límite.
'''
      : '''
"Available Lending Capital" works as a safety limit and financial planning tool for your lending business.

**What is it for?**
This value sets a maximum ceiling for the total capital you can have lent out (on the street) at any given time. It is not a real bank account, but an administrative limit you define yourself.

**What happens if I enable it?**
When "Validate Working Capital" is enabled, before creating a new loan, the system will check if you have sufficient available balance.

1. **Calculation:** The sum of all active lent capital is subtracted from this global limit.
2. **Validation:** If the new loan exceeds the remaining amount, the system will warn you and prevent loan creation to avoid unplanned overdrafts.

**Recommendation:**
Keep this value updated according to your actual investment capacity or the budget you have assigned for your loan portfolio. If your business grows, remember to increase this limit.
''';

  // ==========================================
  // Capitalize Interest
  // ==========================================
  static String capitalizeInterestTitle(bool isSpanish) =>
      isSpanish ? 'Capitalización de Intereses' : 'Interest Capitalization';

  static String capitalizeInterestDescription(bool isSpanish) => isSpanish
      ? '''
Esta opción permite convertir los intereses no pagados en nuevo capital.

**¿Qué significa?**
Si un cliente no paga sus intereses a tiempo, estos se suman al saldo capital del préstamo, generando nuevos intereses sobre el monto acumulado (interés compuesto).

**Uso:** Habilita esta opción si tu modelo de negocio cobra interés sobre interés en caso de mora prolongada.
'''
      : '''
This option allows converting unpaid interest into new principal.

**What does it mean?**
If a customer fails to pay interest on time, it is added to the loan's principal balance, generating new interest on the accumulated amount (compound interest).

**Usage:** Enable this if your business model charges interest on interest for prolonged delinquency.
''';

  // ==========================================
  // Daily Accrual
  // ==========================================
  static String dailyAccrualTitle(bool isSpanish) =>
      isSpanish ? 'Acumulación Diaria (Prorrateo)' : 'Daily Accrual (Prorated)';

  static String dailyAccrualDescription(bool isSpanish) => isSpanish
      ? '''
Controla cómo se cobran los intereses si el cliente cancela el préstamo antes de tiempo.

**Activado:**
Se cobra interés solo por los días exactos transcurridos en el ciclo actual.
*Ejemplo:* Si paga a la mitad del mes, paga solo medio mes de interés.

**Desactivado:**
Se cobra el ciclo completo de interés sin importar el día de pago.
*Ejemplo:* Un día dentro del mes cuenta como el mes entero de interés.
'''
      : '''
Controls how interest is charged if the customer pays off the loan early.

**Enabled:**
Interest is charged only for the exact days elapsed in the current cycle.
*Example:* Paying halfway through the month costs only half a month's interest.

**Disabled:**
The full cycle's interest is charged regardless of the payment day.
*Example:* One day into the month counts as the full month's interest.
''';

  // ==========================================
  // Multiple Loans
  // ==========================================
  static String allowMultipleLoansTitle(bool isSpanish) =>
      isSpanish ? 'Múltiples Préstamos' : 'Multiple Loans';

  static String allowMultipleLoansDescription(bool isSpanish) => isSpanish
      ? '''
**Activado:**
Permite que un mismo cliente tenga varios préstamos activos simultáneamente.

**Desactivado:**
Un cliente debe liquidar su préstamo actual antes de poder solicitar uno nuevo.
'''
      : '''
**Enabled:**
Allows a single customer to have multiple active loans simultaneously.

**Disabled:**
A customer must pay off their current loan before applying for a new one.
''';

  // ==========================================
  // Unique DNI
  // ==========================================
  static String validateDniTitle(bool isSpanish) =>
      isSpanish ? 'Validación de DNI Único' : 'Unique ID Validation';

  static String validateDniDescription(bool isSpanish) => isSpanish
      ? '''
Evita la duplicidad de clientes en tu base de datos.
Al registrar un nuevo cliente, el sistema verificará si el número de identidad (DNI/Cédula) ya existe.
'''
      : '''
Prevents duplicate customers in your database.
When registering a new customer, the system will check if the ID number (DNI/ID Card) already exists.
''';

  // ==========================================
  // WhatsApp Receipts
  // ==========================================
  static String whatsappReceiptsTitle(bool isSpanish) =>
      isSpanish ? 'Recibos por WhatsApp' : 'WhatsApp Receipts';

  static String whatsappReceiptsDescription(bool isSpanish) => isSpanish
      ? '''
Habilita el envío rápido de comprobantes de pago y desembolso a través de WhatsApp.
El sistema generará el PDF y abrirá WhatsApp automáticamente con el archivo listo para enviar.
'''
      : '''
Enables quick sending of payment and disbursement receipts via WhatsApp.
The system will generate the PDF and automatically open WhatsApp with the file ready to send.
''';

  // ==========================================
  // Capital Restriction
  // ==========================================
  static String capitalRestrictionTitle(bool isSpanish) => isSpanish
      ? 'Restricción de Abono a Capital'
      : 'Capital Payment Restriction';

  static String capitalRestrictionDescription(bool isSpanish) => isSpanish
      ? '''
Evita que los clientes abonen al capital si faltan pocos días para su fecha de corte.

**Objetivo:**
Asegurar el cobro completo de los intereses del ciclo. Si abonan capital muy cerca de la fecha de pago, el interés calculado bajaría drásticamente, afectando tu ganancia esperada.

**Configuración:**
Tú defines cuántos días antes del corte se activa este bloqueo (ej. 10 días).
'''
      : '''
Prevents customers from paying down principal if there are few days left until their cutoff date.

**Goal:**
Ensure full collection of cycle interest. If principal is paid too close to the payment date, the calculated interest would drop drastically, affecting your expected profit.

**Configuration:**
You define how many days before the cutoff this block is activated (e.g., 10 days).
''';

  // ==========================================
  // Tolerance Days
  // ==========================================
  static String toleranceDaysTitle(bool isSpanish) =>
      isSpanish ? 'Días de Tolerancia (Mora)' : 'Grace Period Days';

  static String toleranceDaysDescription(bool isSpanish) => isSpanish
      ? '''
Días adicionales que otorgas después de la fecha de pago antes de considerar el préstamo en "Mora".

**Ejemplo (2 días de tolerancia):**
Si paga el día 1 o 2 después de la fecha límite, se considera puntual. Al día 3, pasa a estado de Mora.
'''
      : '''
Additional days you grant after the payment date before considering the loan "Overdue".

**Example (2 days grace period):**
If paid on day 1 or 2 after the deadline, it's considered on time. On day 3, it becomes Overdue.
''';

  // ==========================================
  // Payment Order
  // ==========================================
  static String paymentOrderTitle(bool isSpanish) =>
      isSpanish ? 'Orden de Aplicación de Pagos' : 'Payment Application Order';

  static String paymentOrderDescription(bool isSpanish) => isSpanish
      ? '''
Define la prioridad con la que se distribuye el dinero recibido.

**Interés Primero (Recomendado):**
1. Mora pendiente
2. Interés corriente
3. Abono a capital

**Capital Primero:**
1. Descuenta capital directamente
2. Luego cubre intereses
*Nota: Esta opción reduce el saldo más rápido pero puede afectar la recuperación de intereses.*
'''
      : '''
Defines the priority with which received money is distributed.

**Interest First (Recommended):**
1. Pending late fees
2. Current interest
3. Principal payment

**Principal First:**
1. Deducts directly from principal
2. Then covers interest
*Note: This option reduces the balance faster but may affect interest recovery.*
''';

  // ==========================================
  // Report Settings
  // ==========================================
  static String reportSettingsTitle(bool isSpanish) =>
      isSpanish ? 'Configuración de Reportes' : 'Report Configuration';

  static String reportSettingsDescription(bool isSpanish) => isSpanish
      ? '''
Personaliza la apariencia de los recibos PDF que entregas a tus clientes.

* **Firmas:** Añade líneas para firma de "Entregado por" y "Recibido por".
* **Leyendas:** Añade textos legales o notas al pie (ej. "Gracias por su pago", "Sujeto a mora por atraso").
'''
      : '''
Customize the appearance of PDF receipts given to your customers.

* **Signatures:** Adds lines for "Delivered by" and "Received by" signatures.
* **Legends:** Adds legal text or footnotes (e.g., "Thank you for your payment", "Subject to late fees").
''';

  // ==========================================
  // Sequences (Consecutivos)
  // ==========================================
  static String sequencesTitle(bool isSpanish) =>
      isSpanish ? 'Consecutivos' : 'Sequences';

  static String sequencesDescription(bool isSpanish) => isSpanish
      ? '''
Permite ajustar manualmente los números de control para Préstamos y Recibos.

**Préstamos:**
Define el número del *último* préstamo creado (ej. 100). El siguiente préstamo será 101.
Útil si migras datos de otro sistema y quieres continuar tu numeración.

**Recibos:**
Igual que los préstamos, define el último número generado para los comprobantes de pago.
'''
      : '''
Allows manual adjustment of control numbers for Loans and Receipts.

**Loans:**
Defines the number of the *last* created loan (e.g., 100). The next loan will be 101.
Useful if you are migrating data from another system and want to continue your numbering.

**Receipts:**
Same as loans, defines the last number generated for payment receipts.
''';

  // ==========================================
  // Maintenance (Mantenimiento)
  // ==========================================
  static String maintenanceTitle(bool isSpanish) =>
      isSpanish ? 'Mantenimiento y Respaldos' : 'Maintenance & Backups';

  static String maintenanceDescription(bool isSpanish) => isSpanish
      ? '''
Herramientas críticas para proteger y gestionar tus datos.

**Exportar Respaldo:** Crea una copia completa de tu base de datos. ¡Haz esto regularmente!
**Carpeta de Respaldo:** Elige dónde se guardan los respaldos (útil para sincronizar con la nube).
**Restaurar:** Recupera tus datos desde un archivo de respaldo anterior.
**Recalcular Cartera:** Corrige inconsistencias en saldos si notas errores en los cálculos.
**Borrar Datos:** *Zona de Peligro*. Elimina datos permanentemente para reiniciar o limpiar.
'''
      : '''
Critical tools to protect and manage your data.

**Export Backup:** Creates a full copy of your database. Do this regularly!
**Backup Folder:** Choose where backups are saved (useful for cloud syncing).
**Restore:** Recover your data from a previous backup file.
**Recalculate Portfolio:** Fixes balance inconsistencies if you notice calculation errors.
**Delete Data:** *Danger Zone*. Permanently removes data to reset or clean up.
''';

  // ==========================================
  // Appearance (Apariencia)
  // ==========================================
  static String appearanceTitle(bool isSpanish) =>
      isSpanish ? 'Apariencia' : 'Appearance';

  static String appearanceDescription(bool isSpanish) => isSpanish
      ? '''
Personaliza cómo se ve la aplicación.

**Modo Claro:** Ideal para entornos muy iluminados.
**Modo Oscuro:** Reduce la fatiga visual y ahorra batería.
**Sistema:** Se adapta automáticamente a la configuración de tu teléfono.
'''
      : '''
Customize how the application looks.

**Light Mode:** Ideal for bright environments.
**Dark Mode:** Reduces eye strain and saves battery.
**System:** Automatically adapts to your phone's settings.
''';

  // ==========================================
  // Language (Idioma)
  // ==========================================
  static String languageTitle(bool isSpanish) =>
      isSpanish ? 'Idioma' : 'Language';

  static String languageDescription(bool isSpanish) => isSpanish
      ? '''
Cambia el idioma de toda la interfaz de la aplicación.
Actualmente soportamos Español e Inglés.
'''
      : '''
Change the language of the entire application interface.
We currently support Spanish and English.
''';

  // ==========================================
  // About (Acerca de)
  // ==========================================
  static String aboutTitle(bool isSpanish) => isSpanish ? 'Acerca de' : 'About';

  static String aboutDescription(bool isSpanish) => isSpanish
      ? '''
Información sobre la versión instalada y el desarrollador.
Aquí puedes verificar si tienes la última actualización y contactar a soporte si es necesario.
'''
      : '''
Information about the installed version and the developer.
Here you can check if you have the latest update and contact support if needed.
''';
}
