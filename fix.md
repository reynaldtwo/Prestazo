# Fix y Mejoras - AppPrestamos

Fix a mejorar:

Pantalla Registrar Préstamo

1) Si el usuario selecciona Cancelar préstamo, entonces si en Ajuste está activo cobrar mora en días de atraso, entonces cobrar esos días que están fuera del ciclo. Ejemplo: un préstamo quincenal, fecha de desembolso 01-12-25, fecha de pago 18-12-25; en este caso se cobran 3 días adicionales ya que su corte era el 15.
   Pero si el usuario selecciona algo distinto (tipo de pago <> “Cancelar”), entonces solo cobrar intereses del ciclo, aunque la fecha de pago sea mayor que la fecha de pago del ciclo.

2) Hice un préstamo a un cliente con frecuencia quincenal, fecha desembolso = 01-11-25. Yo esperaba que el comportamiento para este caso sea: al seleccionar el préstamo aparezcan 3 ciclos en estado vencido, pero no lo hace, solo muestra el primero.
   El app debe ser capaz de ir girando ciclos automáticamente al finalizar el ciclo. Por ejemplo: para este mismo caso, el día 16-11-25 debió haber amanecido con un segundo ciclo, el primero vencido y el segundo corriendo; el 01-12-25 debió amanecer con 3 ciclos, 2 vencidos y 1 corriendo. Esto debe aplicar para quincenal y mensual.

3) Al registrar un pago, si el usuario selecciona “Cancelar” préstamo, en campo Monto a pagar debe poner el capital más los intereses acumulados, tanto de los períodos (ciclos) vencidos como de los días del ciclo corriendo; esto último solo si en Ajuste está activada la opción de cobrar días moras.
   Si el usuario selecciona “Mixto” al registrar el pago, se debe validar que el monto digitado cubra todos los intereses acumulados más algo de capital, o al menos que cubra los intereses acumulados (para este caso, los intereses de los días del ciclo corriente no se consideran), ya que el préstamo sigue vivo.

   A- Si el usuario selecciona “Solo interés”, asegurarse que el monto sea el total de los intereses acumulados (excepto intereses de los días del ciclo corriente), ya que el préstamo sigue vivo.

   Si el cliente selecciona “Solo capital”, se debe validar que no hayan intereses o ciclos pendientes de pago. Para este caso, si el cliente no tiene ciclos o intereses pendientes, entonces sí se puede agregar o abonar al capital siempre y cuando el ciclo esté iniciando (este punto debe ser parametrizado en Ajuste) y debe obedecer a esa configuración.

Ejemplo:
Si abonar al capital antes de 10 días antes del corte del ciclo corriendo y el prestatario tiene un préstamo, frecuencia quincenal, fecha desembolso 15-12-25 y quiere abonar al capital hoy 18-12-25, entonces sí puede agregar el abono, pero si la fecha del pago es 28-12-25; entonces sí podría hacer el pago, pero sí o sí deberá pagar los intereses de ese ciclo ya casi por concluir. Otro aspecto a considerar también es que debe ir al día con los ciclos.

Para el punto A del punto 3, cuando el usuario selecciona pagar “Solo interés”, permitir abonar intereses parciales. Ejemplo:
Si un cliente tiene 3 ciclos vencidos y todos ellos suman 1500, sin meter los días del ciclo corriendo, entonces puede abonar 100, o 600, o 700; pero debes distribuirlos entre los períodos.
Ejemplo: 3 ciclos de 500 cada ciclo, y abona 700; entonces cancela el más antiguo y abonas 200 al siguiente. Y si después abona otros 700, entonces cancela el segundo ciclo con 300 y abonas 200 al tercero. Esto debe aplicarse a ambas frecuencias.

4) En la pantalla Reportes Financieros el filtro no funciona íntegramente. Si hay pagos entre el 01-12-25 a 18-12-25 no los muestra; para que los muestre se debe poner un día de más en la fecha final, quedando así: 01-12-25 a 19-12-25, y eso está mal. Revísalo y asegura que funcione íntegramente.

5) Cuando selecciones un préstamo, debes agregar una nueva función (pantalla) que permita modificarlo.

6) Al seleccionar un préstamo y moverlo hacia la izquierda (slide), eliminarlo, pero solo si el usuario confirma la acción; o en cada préstamo puedes agregar un ícono para eliminarlo directamente desde ahí.

7) Cada vez que se agreguen préstamos, debes validar el campo “Permitir préstamos a un mismo cliente aunque tenga créditos activos”.

8) En Ajuste, agregar toggle que indique si un cliente puede tener más de 1 préstamo activo (se considera activo cuando no ha sido cancelado). Este punto es para poder hacer la validación del punto 7.

9) En Ajuste, opción Borrar todos los datos, hay que hacerlo por entidad, de modo que el usuario pueda seleccionar la entidad a limpiar, pero debe ser de forma lógica. Ejemplo: si desea eliminar clientes y al menos 1 cliente tiene préstamos activos, entonces no puede, pero debes indicarle que si lo borra se elimina todo lo asociado al cliente.

   Ejemplo de eliminación:
   Borrar pagos
   Borrar préstamos
   Borrar clientes

   Si el usuario selecciona Borrar pagos, se deben borrar solo los pagos, nada más.

   Como este proceso es delicado, debes pedir la confirmación del usuario y antes de eliminar debes crear una copia o backup, de modo que el usuario pueda hacer rollback desde otra pantalla.

10) En Ajuste, agregar un apartado para manejar el tema de Respaldo.
    El usuario, si activa la opción, debes pedirle correo y debes validarlo para poder guardar en drive de ese correo las copias o backup creados.

    Hacerlo de la misma forma que lo hace WhatsApp actualmente.

    La forma que validarás el correo puede ser así: envías un código único al correo, el usuario tendrá que digitarte (entregarte) el código; si es el que enviaste, puedes dar por validado el correo.

    Aspectos que debes pedirle al usuario que debe configurar en ese mismo apartado:

    1) Frecuencia de creación de backup: puedes presentarle las siguientes opciones
       - Diario a las 05:00 am
       - Diario a las 12:00 pm
       - Diario a las 22:00 pm
       - Diario a las (“permitir poner la hora”)
       - Diario al finalizar una transacción (transacciones) como:
         • Nuevo cliente
         • Nuevo préstamo
         • Nuevo pago o abono

    2) Internamente, debes conservar el último respaldo para no saturar el almacenamiento (me refiero al almacenamiento en el teléfono).

    3) Debes crear un proceso interno que, según la configuración del punto 1 (frecuencia de creación de respaldo), este proceso debe validar si hay internet; si hay, debe subir el respaldo (el último) al drive y conservar el último en el dispositivo y eliminar los demás.

       Este proceso debe ser tipo promesa; si el respaldo no se logra subir, debe volver a intentarlo, pero al volver a intentarlo debe validar que no haya un nuevo respaldo hecho; si lo hay, debe tomar el más reciente.

       Este proceso debe ser silencioso y no debe afectar o bloquear ningún otro proceso.

11) También debes diseñar una pantalla para poder gestionar los respaldos. En esta pantalla vas a mostrar los respaldos creados y que no han sido eliminados del dispositivo, para que el usuario pueda eliminarlos manualmente. Ojo: acá no puedes eliminar el último (más reciente).

    En esta pantalla, agregar opciones para crear nuevos respaldos o subirlos manualmente.

    En esta misma pantalla, también permitir cambiar el correo donde se almacena la copia de seguridad.

    Agrega todas las opciones necesarias y que no estoy considerando en este momento.

12) En Ajuste, agregar opción de restaurar copia de seguridad. Si el cliente selecciona restaurar copia de seguridad, puedes mandarlo a la pantalla del punto 11 para que el usuario proporcione el correo de donde vas a tomar la copia de seguridad.

    Si para poder hacer todo el tema de respaldo y restauración en el correo necesitas contraseña del correo o cuenta de Google, agrégalo al requerimiento para que lo consideres y lo solicites al usuario de la forma más lógica y eficiente posible.

    u) Copias de seguridad deben ser tanto local como en el drive; esto debes preguntarle al usuario cuando seleccione la opción de respaldar.

    Para todo este tema de respaldo, diseña un flujo moderno y fácil para el usuario.

13) En Ajuste, agrega configuración para manejar temas oscuro y claro (solo esos dos temas poner como disponibles).

14) Agregar multi idioma, agrega los idiomas más comunes.

15) Antes de hacer cualquiera de estos puntos, lee toda la documentación y todo el proyecto desarrollado al momento y aplica las mejores prácticas de desarrollo.
    Ejemplo: centraliza todo lo que es cálculo para que solo mandes a llamar desde donde lo vayas a necesitar en el flujo.

    Los componentes, crealos aparte bien estructurados para que los podas reutilizar.
    Ejemplo: crea un botón guardar, y ese mismo botón lo usas en todas las pantallas donde sea necesario.

    Los colores también ponelos aparte centralizados: las fuentes, los idiomas.

    Las tablas SQLite, revísalas para identificar si se necesitan extender las tablas o campos para cumplir con todos los puntos a desarrollar.

    Crea una estructura de documentación para que documentes todo el proyecto, incluyendo: base de datos, tablas, clases, procedimientos, fórmulas de cálculos, documentación técnica, documentación funcional, documentación de arquitectura implementada.

16) Notas importantes durante el desarrollo: asegúrate de tener bien clara la lógica a implementar; todo debe ser de forma lógica. Si haces un cambio en los cálculos, asegúrate de que realmente todo funcione.

17) Asegúrate de que cada vez que finalices una transacción como un préstamo nuevo, un pago, todas las pantallas que muestran información relacionada se deben refrescar automáticamente; actualmente no se hace.

18) En Ajuste, agrega opción para permitir a los clientes su comprobante de pago por WhatsApp (esto solo si es posible). Si no es posible, me lo decís.

19) En historial de préstamo, agrega opción para reimprimir comprobantes de pago.

20) Agrega pantalla para ver historial de pago (solo si no existe) y agrega opción de enviar un PDF del estado de cuentas al cliente o descargarlo.

21) Analisa todo esto nuevo y lo que ya está desarrollado, y si hay algo que falte para poder implementar todo, agrégalo y arma un plan de implementación y desarrollo, y crea los unit test para probar. Al finalizar el desarrollo, me presentas un documento con escenarios de pruebas para cada flujo.

22) Las opciones “Inicio”, “A cobrar”, “Clientes”, “Reportes”, “Ajuste” siempre deben ser visibles cuando se abra cualquier pantalla; esto facilita la navegación.

Nota: Estructura todos estos cambios de forma lógica, ya que están desordenados, y actualiza la documentación, el requerimiento.
