REQUERIMIENTO TÉCNICO:

 Corrección de Arquitectura Multimoneda, Lógica de Visualización y UI ResponsivaAsunto: 
 
 Fix Urgente: Integridad de Símbolos de Moneda, Consistencia Aritmética y Layout Flexible. se han detectado fallos críticos en la última implementación que comprometen la fiabilidad financiera de la app. Es imperativo que las correcciones se hagan de forma dinámica, utilizando los objetos de moneda definidos y NUNCA valores estáticos (hardcoded) en el código.
 
 1. Integridad de la Moneda del Préstamo (Error de Símbolo)Se ha detectado que al cambiar la "Moneda de Visualización" en Ajustes, el sistema altera erróneamente el símbolo de los préstamos ya otorgados.REGLA: La moneda original de un contrato de préstamo NUNCA debe cambiar. Si un préstamo se otorgó en "Moneda A", debe conservar siempre el símbolo de "Moneda A" en el detalle del préstamo y recibos.FALLO: Un préstamo de 200 USD aparece con el símbolo de NIO (o viceversa) al cambiar la vista global.SOLUCIÓN: Todos los widget o campos de las  pantalla de préstamo como detalle de prestamos, registrar pago o cualquier otra pantalla donde se muestre informacion de prestamos otorgados debe leer la propiedad currency_symbol directamente del objeto del préstamo, no de la configuración global de visualización incluso la recibos de pago, comprovantes de desembolso o cualquier otro ducumento que sea para el cliente, debe leer de la propiedad currency_symbol directamente del objeto del préstamo.
 
 2. Consistencia Aritmética en Dashboard (Lógica Dinámica)El Dashboard muestra cálculos incoherentes. Deben unificar la lógica de valoración usando la Tasa de Venta de forma dinámica:Cálculo de Capital Colocado: Debe ser la suma de todos los préstamos convertidos a la moneda base usando la tasa de venta histórica del contrato.
 
 Cálculo del Capital Total (Techo): Al visualizar en una moneda distinta a la base, el "Techo" debe convertirse usando la tasa de venta actual.Ejemplo: Si el Techo es 20,000 (Base) y la Tasa es 37.00, el Dashboard debe mostrar "de 540.54". Actualmente muestra valores que no cuadran (como 556), indicando una tasa errónea.Porcentaje de Ocupación: Debe ser exactamente (Capital Colocado / Capital Total) * 100. No pueden existir diferencias de redondeo ni de tasas entre el texto y la barra de progreso.
 
 3. Pantalla de Pagos y Utilidad CambiariaImplementar selector de Moneda de Pago (NIO/USD o cualquier otra configurada).Si la moneda de pago es distinta a la del préstamo, el sistema debe proponer la Tasa de Venta pero permitir edición manual.Registro de Ganancia: Guardar en el campo utilidad_cambiaria la diferencia entre el monto recibido y el monto esperado según la tasa oficial.
 
 4. UI/UX y Responsividad (Cero Overflows)Ajustes de Idioma/Tema: Los botones están amontonados. Usen SegmentedButton o layouts flexibles que se adapten al ancho del dispositivo.Tarjetas de Tasas: Eliminen anchos fijos. El texto "Tasa Venta: 37.0000" se sale de la tarjeta; usen Flexible o FittedBox.Jerarquía en Inicio: Aumenten el tamaño de las etiquetas de las tarjetas y reduzcan el padding excesivo. La información clave debe ser legible de un vistazo.Instrucción para el Desarrollador (Control de Calidad):Este desarrollo solo se considerará exitoso si:El símbolo del préstamo de $200 permanece como "$" sin importar los ajustes de visualización.La matemática del Dashboard cuadra al 100% con las tasas configuradas.No hay errores de "Bottom Overflow" ni textos cortados en ninguna resolución de pantalla.

 5. el selector de moneda que esta en Registro de Pago no es funcional, no tiene barra de buzqeda, debe ser igual a lo que estan implementados en Ajustes, en gestion de moneda, y para lograr esto, desarrollo un componente grlobal que sirva para seleccionar moneda y que lo puedas llamar desde cualquier parte del app. 

 6. EN pantalla Registrar Pago el campo Moneda de Pago subilo hacia arriba del campo moneda de pago , de modo que sea el primer campo que se seleccione , despues el siguiente campo tiene que ser Tasa de cambio Aplicada y este campo siempre debe ser visible.

 7. al finalizar reconstruye el apk para probar, pero asegurate de que todo se haya aplicado correctamente. consulta el MCP de flutter para hacer cualquier investigacion para que te apoyes.

 02-01-2026

 Fix encontrado tras las pruebas:

 1. Inicialmente en ajustes se selecciona como moneda base NIO y se creo un capital de trabajo de 20,000 córdobas y se selecciono USD como moneda de visualización, posterior se realizo un prestamo de 200 USD, y despues se fue a revisar la pantalla de Inicio para ver el indicador capital colocado y muestra como capital colocado 200 USD, 37% de $548. Hasta ahi todo bien, pero despues se fue a ajustes y se seleccino NIO como moneda de visualizacion y se fue a valdiar la pantalla de Inico y muestra como capital de trabajo 7,400 NIO, 37% de C$ 20274. esos 20274 no se de donde los saca, y hay que corregirlo.

 segerencias: crea procesos centralizados que se encarguen de realizar las operaciones de conversion de monedas, o de operaciones matematicas, para que no se repita codigo en todo el proyecto o pantallas y que en cualquier cambio que hagas puedas facilmente corregirlo.

 Crea un  documento en donde documentes todo el proceso de conversion de monedas y las operaciones matematicas que se realizan en todo el proyecto.

 Investiga en el MCP de flutter para hacer cualquier investigacion para que te apoyes.

 Posterior al finalizar, recontruye por completo el apk para probar, pero asegurate de que todo se haya aplicado correctamente.

Pruba ·1
 2. se realizo prueba y ahora pasa lo siguiente: cuando se hace un cambio de moneda de visualizacion, por ejemplo se paso a NIO, en Inicio ahora muestra capital colocado 7,400 NIO, 37% de C$ 20000. pero cuando se cambia la moneda de visualizacion a USD, muestra capital colocado 205.56 USD, 37% de C$ 556, esto esta malo, revisa bien la logica implementada y aplica formato de miles correctamente a los montos, por ejemplo cuando la moneda es NIO muestra 20000 y no aplica formato de miles correctamente.


 05-01-2026
 Mejoras en pantalla Rerpotes

 1. Diseñar un menul (lider) que tenga las siguientes opciones:
    - Ganancias Reales
    - Proyecciones
este menu debe estar disponible en la pantalla de Reportes y debe estar ubicado en la parte izquierda de la pantalla, con opnes de mostrar y contraer de forma que le sea facil al usuario seleccionar la opcion que desea ver. cada vez que el usuario seleccione una opcion, debe contraer el menu y mostrar la pantalla correspondiente. y en caso de que haya una pantalla seleccionada, debe contrararla, adecuadamente.

Investiga en el MCP de flutter para hacer cualquier investigacion para que te apoyes.

Las 2 opciones que se te estan pidiendo son la que ya existen actualmente en la pantalla de Reportes, solo que se te pide que se muestren de forma diferente, es decir, que se muestren en un menu lateral que se puede mostrar y contraer.

2. Ahi mismo en Reportes en las pestañas de Ganancias Reales y Proyecciones, hay indicadores de Ganancias Reales y Ganancias mensuales proyectadas, ambos indicadores muestran ganancias, pero tiene un problema: el problema es que esta sumando las ganancias de todos los prestamos, de forma literal, y no es asi. La forma correcta es que tomes cada prestamo y calcules la ganancia real o proyectada segun la moneda de cada prestamo y lo conviertas a la moneda base y sume los valores de cada prestamo ya convertidos a moneda base para obtener el total de ganancias reales o proyectadas y despues ese total lo conviertas a la moneda de visualizacion y lo muestres en el indicador. ya que un prestamista puede tener prestamos en diferentes monedas.
 
 Nota: para desarrollar el nuevo menu lateral, debes seguir la misma linea de diseños que actualmente tenemos implementado en todo el app(proyecto) con los mismos colores y estilos.
 


 06-01-2026
 Mejoras en diseños y procesos

 Pantalla de reportes: 

 1. Quitar el bigets que se muestra en la pantalla de reportes, el que hace que se contraiga el menu lateral. y rediseñar el menu lateral para que sea mas agradable al usuario,toma como la iamgen que te estoy proporsionando. debe mantener nuestros colores y la funcionalidad de contraer el menu cada vez que se seleccione una opcion.

2. cuando el menu este contraido, debe haber un indisio de que ahi esta el menu , para eso investiga en el MCP de flutter para saber como lo hacen los pro. o investiga en la web para saber como lo hacen los pro.



Pantalla Registro de pago

1. Escenario : Un prestamo con moneda NIO monto del prestamo 10,000 NIO, interes=10%, frecuencia=Quincenal, Fecha desembolso=01-12-2025. A la fecha tiene 2 cliclos vencidos y uno corriendo. en ajustes la tasa de cambio (compra)para la fecha en la que se esta efectuando el pago USD ---> NIO es de 37. El usuario selecciono USD como moneda de pago, el app automaticamente  cargo la tasa de cambio. hasta ahi todo esta bien. Pero cuando el usuario selecciona la opcion "Solo Interes" la app carga el monto 36,260.00 USD. lo cual es una cifra errada. y lo mismo ocurre con las demas opciones "Solo Capital", "Cancelar".

Como podemos hacer para que el app calcule correctamente el monto de pago en la moneda de pago seleccionada?

Toma en cuenta que un prestamo puede ser pagado en una moneda distinta a la moneda del prestamo, tabien considera que el prestamista debe ganar cuando sucede eso por eso es que se aplica la tasa de cambio de compra para que el prestamista gane al realizar la transaccon, esa ganancia debe ser registrada en los campos correspondientes, para mas adelante poder sacar un reprote de ganancias por pagos en otras monedas.

otra cosa que debes considerar es que debe existir siempre una validacion, cuando el usuario seleccione una moneda para pagar que no sea la de la base, el app debe validar que exista una tasa de cambio para la fecha en la que se esta efectuando el pago, si no existe debe mostrar un mensaje de advertencia y no permitir que el usuario continue con el pago, hasta que se guaerde una tasa de cambio. 


Escenario en flujo del prestamo:

Datos del prestamo:

1. Prestamo por 2,000 en moneda NIO.
2. fecha de desembolso 15-12-2025
3. El app genero 3 ciclos vencidos y 1 corriendo.
4. fecha actual 07-01-2026
5. Interes=10%
6. Frecuencia=Semanal

Datos de las tasas de cambio guardadas en Ajustes:

1. USD ---> NIO es de 37. "Venta"
2. USD ---> NIO es de 36. "Venta"

Datos del pago aplicado:

1. se selecciono USD como moneda de pago.
2. se selecciono "Solo Interes"
3. se digito 4.05 USD como monto a pagar.
4. se presionno el boton Registrar Pago.
5. salio el mensaje informativo que dice: 

"Confirmar pago" 
monto del prestamo: C$5.00
Cliente: JOSE MANUEL
.A interés vencido: C$ 5.00

se presiono el boton Confirmar Pago.

y posterior nos regresa a la pantalla detalle del préstamo y todas las cuotas(ciclos) siguen iguales, el pago que se hiso, no se aplico a ninguna cuota(ciclo). 

¿Que debes hacer?
Debes analizas bien el flujo desde la creacion de prestamos hasta el registro de pagos y cancelacion del mismo y tambien revisa la reporterias para que todo tenga sentido y funcione correctamente.

Cuando finalice create este mismo escenario de prueba y otro pagando con la misma moneda del prestamo. si las pruebas son exitosas, procedes a reconstruir el APK para realizar las pruebas en el celular.



/*08  enero 2026 */

Revisa estos casos 1 a uno y resuelve los errores que aparezcan.

CASO 1:

Escenario en flujo del prestamo:
Caso: Pago de solo intereses en ciclos vencidos.
Datos del prestamo:

1. Prestamo por 10,000 en moneda NIO.
2. fecha de desembolso 01-12-2025
3. El app genero 2 ciclos vencidos y 1 corriendo.
4. fecha actual 08-01-2026
5. Interes=10%
6. Frecuencia=Quincenal
7. valor de cada cuota vencida 500 NIO

Datos de las tasas de cambio guardadas en Ajustes:

1. USD ---> NIO es de 37. "Venta"
2. USD ---> NIO es de 36. "Venta"

Datos de los pago aplicado:

1. se selecciono NIO como moneda de pago.
2. se selecciono "Solo Interes", parcialmente
3. se digito 900 NIO como monto a pagar.
4. se presionno el boton Registrar Pago.

el pago se deistribuyo correctamente , se cancelo el primer ciclo por 500 NIO y se abono 400 NIO al segundo ciclo, quedando un saldo del segundo ciclo de 100 NIO

Posteriormente se realizo otro pago al mismo prestamo por 50 NIO y el sistema abono correctamente los 50 NIO al segundo ciclo y quedo un saldo de 50. 

Despues se realizo otro pago por 50 NIO y se esperaba que el segundo ciclo se cancelara , pero no sucedio y en el historial de pagos no aparece ese pago, es como que no se aplico.

Dato curioso: Hice otro escenario con los mismos datos y hice 9 abonos de  100 NIO y todo bien, pero ya cuando me quedo un saldo de 100 NIO del segundo ciclo y lo quise cancelar, ahi sucede eso, que no se registra el pago.

Revisa bien que esta sucediento y hace pruebas para asegurarte de que realmente los cambios que vayas a realizar , funcionen correctamente.



CASO 2:

Error en pantalla detalle prestamo al presionar el boton compartir estado de cuenta, sale el mensaje de error: 

"Error al generar PDF: DatabaseException(no such column: loan_id (code 1 SQLITE_ERROR[1]): , while compiling: SELECT * FROM payment_allocations WHERE loan_id = ?) sql 'SELECT * FROM payment_allocations WHERE loan_id = ?' args [6020ecd1-3e24-44c6-95be-9671cc4a3d3e]
"

CASO 3:

En la pantalla de Reportes da este error:

"type 'Null' is not a subtype of type 'num' in type cast"


***Corregido ***





/*08  enero 2026 */

Tomate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Y apoyate del MCP de flutter para resolver los errores que aparezcan.

CASO 1:

Escenario en flujo del prestamo:
Caso: Pago de solo intereses en ciclos vencidos, con monedas distinta a la moneda del prestamo.
Datos del prestamo:

1. Prestamo por 10,000 en moneda NIO.
2. fecha de desembolso 01-12-2025
3. El app genero 2 ciclos vencidos y 1 corriendo.
4. fecha actual 08-01-2026
5. Interes=10%
6. Frecuencia=Quincenal
7. valor de cada cuota vencida 500 NIO

Datos de las tasas de cambio guardadas en Ajustes:

1. USD ---> NIO es de 37. "Venta"
2. USD ---> NIO es de 36. "Venta"

Datos de los pago aplicado:

1. se selecciono USD como moneda de pago.
2. La app cargo automaticamente la tasa de cambio de compra guardada en Ajustes por un monto de 36
2. se selecciono "Solo Interes" y el sistema cargo en el campo monto a pagar el valor de 27.78 USD
3. Hay un campo que aparece debajo del campo Tasa de Cambio en los verde, en el que se muestra: Cobrar al cliente : $ 1,000.08 (en este indicador deberia de mostrar la moneda a la cual se convertio el pago, actualmente muestra "$" y eso visualmente cualquiera entenderia que el pago se hizo en dolares)
4. se presiono el boton Registrar Pago.
5. el pago se guardo correctamente.
6. Se confirmo el pago mediante el dialogo "Confirmar Pago"
7. En la pantalla Detalle del Préstamo, en el historial de pago, se muestra que la transaccion que se hiso (pago) con la moneda USD , guardo 0.08 y los abono a la cuota(ciclo) Pendiente.

Que hacer:

Calcular monto exacto a aplicar (interés/capital/Abonos)

Aplicar SOLO hasta el monto adeudado

Si hay excedente por conversión:

NO aplicar a ciclos

NO aplicar a capital

MUY IMPORTANTE:

Cualquier exceso por:

1. Redondeo
2. Tipo de cambio
3. Conversión

👉 NO reduce deuda futura automáticamente
👉 NO adelanta pagos
👉 NO genera saldos “raros” en cuotas

Ese exceso se clasifica como:

1. Diferencial cambiario positivo
2. Ganancia por tipo de cambio
3. Ingreso financiero 



Registrar como Diferencial Cambiario a Favor.(Revisa si existe en el esquema de la base de datos, una tabla donde se vaya registrando estos tipos de movimientos por conversion de moneda, si no existe, debes crearla, ya que mas adelante te pedire un reporte de ganancias por diferenciales cambiarios.)

Esos difenciales cambiarios, deben tener la informacion necesaria para que el reporte de ganancias por diferenciales cambiarios, pueda mostrar los datos de donde bienen , de que prestamo, de que cliente, de que fecha, de que monto, de que tipo de cambio, de que moneda, de que tipo de movimiento, de que estado, etc. 


En pantalla de Reportes:

1. Quitar los botones que estan en cabezera de la pantalla de Reportes, boton de compartir y refrescar, esos botones deben estar dentro de cada reporte. ejemplo : dentro del reporte Ganancias reales (debe tener sus propios botones de compartir y refrescar), Proyecciones (debe tener sus propios botones de   compartir y refrescar), etc. y caca pantalla de reporte debe tener su propio nombre , por que cuando abris un reporte no te aparece el nombre del reporte.

2. el reporte de ganancias por diferencial cambiario, debe tener el mismo formato de la iamgen adjunta, tomalo de ejemplo.

Me entendistes mal: Cuando te dije que cambiaras el formato del reporte de gancias por diferencial cambiario, me referia al pdf que se comparte, la pantalla estaba bien, deja la pantalla a como estaba y solo cambia el formato del pdf que se comparte.

Tambien revisa bien el reporte de proyecciones no veo el boton de compartir, solo se ve el boton de refrescar.

Aprovechando que estas revisando los reportes, agrega una columna al reporte PDF de diferenciales cambiarios, que muestre el numero del recibo.














/*08  enero 2026 */

Tomate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Y apoyate del MCP de flutter para resolver los errores que aparezcan.

CASO 1:

Escenario en flujo del prestamo:
Caso: Indicador "Total cobrado hoy" en pantalla de inicio no respeta la moneda de visualizacion.

Datos del prestamo:

1. Prestamo por 10,000 en moneda NIO.
2. fecha de desembolso 01-12-2025
3. El app genero 2 ciclos vencidos y 1 corriendo.
4. fecha actual 08-01-2026
5. Interes=10%
6. Frecuencia=Quincenal
7. valor de cada cuota vencida 500 NIO

Datos de las tasas de cambio guardadas en Ajustes:

1. USD ---> NIO es de 37. "Venta"
2. USD ---> NIO es de 36. "Venta"

Datos de los pago aplicado:

1. se selecciono USD como moneda de pago.
2. La app cargo automaticamente la tasa de cambio de compra guardada en Ajustes por un monto de 36
2. se selecciono "Solo Interes" y el sistema cargo en el campo monto a pagar el valor de 27.78 USD
3. Hay un campo que aparece debajo del campo Tasa de Cambio en los verde, en el que se muestra: Cobrar al cliente : $ 1,000.08 (en este indicador deberia de mostrar la moneda a la cual se convertio el pago, actualmente muestra "$" y eso visualmente cualquiera entenderia que el pago se hizo en dolares)
4. se presiono el boton Registrar Pago.
5. el pago se guardo correctamente.
6. Se confirmo el pago mediante el dialogo "Confirmar Pago"
7. En la pantalla Detalle del Préstamo, en el historial de pago, se muestra que la transaccioncorrectamente.
8. En pantalla de Inicio indicador "Total cobrado hoy" indica que se cobro un monto de 27.78 y los muestra con simbolo de la moneda de visualizacion ques es en NIO en este caso. Lo correcto seria que mostrara un monto de 1,000 NIOS que aunque el cliente pago en USD un total de 27.78 , pero al final se transformaron a 1,000.08, donde 1,000 eran de las 2 cuotas vencidas y los 0.8, pasaron al diferencial cambiario

Que hacer:
EL indicador debe mostrar el valor ya convertido para el caso donde la moneda de pago sea diferente a la moneda del prestamo junto a la moneda de visualizacion , este indicador debe tener el mismo comportamiento del indicador capital colocado que se tranforma segun la moneda de visualizacion.


**Listo**


/*08  enero 2026 */

Tomate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Y apoyate del MCP de flutter para resolver los errores que aparezcan.

CASO 1:

Todo lo ultimo que se ha desarrollado, aun no es multilenguaje, asi que aplica el multilenguaje a todo lo que se ha desarrollado. Recordad que esta pensada para usarse en todo el mundo y cuando el app se inicia se debe detectar el lenguaje y cargarse automaticamente, y lo mismo para la moneda base, la moneda base debe cargarse segun el idioma del telefono o region.

**Listo**





**Siguiente mejora**

/* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

En Ajustes, crea un nuevo apartado que se llame: "Catálogo". Este apartado tendrá varias opciones, pero ahorita solo agrega una que se llame: "Categorizar cliente como". Esta nueva opción debe mandar a una pantalla dedicada en donde el usuario podrá crear la categoría con opciones de Nuevo, Modificar y Eliminar.

Validaciones:
Al eliminar una categoría se debe validar que la categoría no la tenga ningún cliente asociada. Si la tiene un cliente, mostrar un diálogo con la advertencia y datos relevantes del cliente que la posee y si son varios clientes, solo indicar que hay varios clientes con esa categoría y que antes se debe quitársela a los clientes para poder ser eliminada y no permitir eliminarla.

Ejemplo de las categorías que podrían guardar los prestamistas o financieras:

1. Bueno
2. Muy bueno
3. Regular
4. No prestas
5. Malo

En Clientes (entidad) agregar el nuevo campo que permita categorizar al cliente. Este campo debe permitir seleccionar una categoría desde el catálogo en Ajustes y debe ser opcional.

Ubicación del nuevo campo en la pantalla de Nuevo Cliente: debe ser el primer campo, es decir, antes del nombre del cliente.

Posterior, actualiza la versión de la BD y haz bien la migración de la base de datos, asegurándote de que los nuevos campos sean agregados a la base de datos.


Puntos que debes hacer al finalizar:
1. Agregar multiIdiomas al nuevo desarrollo, a como lo hemos venido haciendo, desde el inicio.
2. NO dejar nada harcodeado.
3. Hacer pruebas del nuevo cambio.
4. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
5. Existe una pantalla de editar datos del cliente, asi que hay que asegurarse de que el nuevo campo se muestre en la pantalla de editar datos del cliente tambien, para que pueda ser editado.
6. Cuando un prestamo es cancelado el 100% , en el momento que se haga la cancelacion, se debe mostrar un dialogo que diga:"Desea calificar a este clinte como:"  y abajo un campo para seleccionar una  de las categorias que se crearon en el catalogo de ajustes, y en el mismo dialo mostrar un boton de cancelar, Calificar y una opcion que diga:"Ahora no". Si el usuario selecciona "Ahora no", el dialogo se debe cerrar y continuar con el proceso. Si presiona Calificar, debes validar que se haya seleccionado una categoría previamente, si no se selecciono una categoria, mostrar un dialogo que diga "Debe seleccionar una categoria" y que no permita continuar hasta que se seleccione una categoria. Si la categoria se ha seleccionado y se presiona Calificar, entonces se debe actualizar ese campo en la entidad de clientes.

**Listo**



**Siguiente mejora**
* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

Revisar lo siguiente:

1. Antes de agregar el dialogo de calificar a un cliente, a la hora de cancelar un prestamo, el sistema leia en ajustes la opcion de enviar comprobantes por whatsApp y si esta activada, debe enviar(compartir) el comprobante por whatsApp al cliente y funcionaba correctamete, pero ahora que agregastes el dialogo de calificar a un cliente, a la hora de cancelar un prestamo, el sistema no envia el comprobante por whatsApp al cliente, aunque el tuggle en ajustes esta activado, revisa bien por que no lo hace y asegurate de lo nuevo que se agrego no interfiera con la funcionalidad de enviar comprobantes por whatsApp al cliente u otras funcionalidades que ta existian.

Puntos que debes hacer al finalizar:

2. NO dejar nada harcodeado.
3. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
4. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
5. Reconstruir el APK, para yo probarlo.

**Listo**








**Siguiente mejora**
* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

Revisar lo siguiente:

1. El apartado de Catalogo en ajustes, movelo hacia arrbia debajo del apartado datos de la empresa.
2. En la pantalla de Agregar Categoría, agrega una opcion para agregar un color a la categoria, diseña un selector de color que permita seleccionar un color y que se guarde en la categoria, el selector de color debe ser diseñado usando las mejores practicas de flutter y debe ser funcional y dinamico y usar un estilo moderno puede ser un selector de color que se pueda personalizar el color.
3. Agregar el icono de informacion al apartado de Catalogo en ajustes, de la misma forma que esta para los apartados como Consecutivo etc, encargate de redactar el mensaje que se mostrara en el dialogo de informacion. explica bien para que funcionara la categoria y que basicamente es para poder categorizar los clientes y mas adelante poder obtener reportes de los clientes por categoria.
4. el texto infomativo para el apartado de catalogo asegurarse de que sea multiIdiomas.
5. En la pantalla de Clientes, Leer en los ajustes la categoria del cliente que tiene asignada y tomar el color y aplicarlo a la tarjeta del cliente, pero al aplicarlo debe ser de forma degradada de izquierda a derecha y con una opacidad de baja de modo que se pueda visualizar todos los texto de la tarjeta del cliente.
6. No dejar nada harcodeado, no los colores, ni texto, ansolutamente nada.
7. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
8. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
9. Reconstruir el APK, para yo probarlo.


Mejoras al selector de color en pantalla Agregar Categoría

1. Necesito implementar un selector de color como el “ColorPicker Demo” del paquete FlexColorPicker (pub.dev: flex_color_picker): rueda HSV + cuadro de saturación/valor (SV).
2. Usar el widget ColorPicker de flex_color_picker y habilitar el picker tipo “wheel” (ColorPickerType.wheel).
3. Referencia: flex_color_picker (FlexColorPicker) y su ColorWheelPicker (HSV wheel).
4. No dejar nada harcodeado, no los colores, ni texto, ansolutamente nada.
5. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
6. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
7. Reconstruir el APK, para yo probarlo.


Adicional a lo ultimo que se te pidio, revisar lo siguiente:
1. en pantalla Agregar Categoría, el texto del campo Nombre de categoria queda por debajo del texto (titulo de la pantalla) Agregar cliente, debes bajar el campo Nombre de categoria un poco para que se pueda visualizar bien.
2. Darle mas intensidad al degradado que se le aplica a las tarjetas de los cliente, es decir que el degradado sea mas fuerte y que se pueda visualizar bien.


Mejoras:
1. en la pantalla Agregar Categoria, cuando se abre el teclado del telefono, la pantalla se recoje , se hace mas pequeña y eso hace que el selector no se vea y los botones, cancelar y guardar quedan escondidos, se tiene que hacer scroll para verlos, eso da una mala experiencia al usuario, haz que los campos y componentes se ajusten automaticamente al tamaño de la pantalla y que se vean bien.

2. quita el degradado que se le aplica a las tarjetas de los clientes, pero haz que el texto de la tarjeta se combine con el color de la tarjeta.
 que no puede pasar:
 1. si el color de tarjeta es negro , el color de texto no puede ser negro o un color uscuro. 
 Lo correcto: si el color de la tarjeta es negro, el color de texto debe ser blanco ahumado o un color claro.
**Listo**


















**Siguiente mejora**
/* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

En ajustes -> Catalogos
Crea una nueva pantalla dedicada para crear Frecuencias de pagos personalizadas.

Ejemplo:
1. Diario
2. Semana
3. Quincenal
4. Mensual
5. Anual   

La pantalla debe tener opciones de Nuevo, Editar y Eliminar, Desactivar y Activar.

Validaciones a tener en cuenta:
1. No se puede eliminar un ciclo que este siendo usado por un prestamo en estado Activo.
2. No se puede desactivar un ciclo que este siendo usado por un prestamo en estado Activo.

Datos de inicio:
En la entodad(tabla) en la base deja registrado los siguientes frecuencias de pagos por defecto, para que el usuario decidir si mantenerlas o editarlas o eliminarlas. 

1. Diario
2. Semana
3. Quincenal
4. Mensual
5. Anual

Advertencias a considerar en el desarrollo:
1. No dejar nada harcodeado, como por ejemplo: los colores, ni texto, ansolutamente nada.
2. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
3. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
4. Reconstruir el APK, para yo probarlo.





Pregunta muy importante.
Para contestar a esta pregunta analiza bien el proyecto

1. ¿cómo calculás las fechas de vencimiento?

Lo haces en Intervalo fijo (quincenal = cada 15 días; semanal = cada 7; mensual = cada 30 o “+1 mes”), o

Calendario real (quincenal = 15 y 30/31, o 1 y 15; semanal = un día específico como lunes; mensual = día X del mes).

dame un resumen claro de como se hace actualmente y mostrame los archicos que contienen la logica implementada.
**Listo**





**Siguiente mejora**
/* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:
En la pantalla Nuevo Prestamo, Vas a quitar las frecuencias de cobros que actualmente tenemos harcodeadas y vas a remplazarlas por las que se encuentran en la tabla de la base de datos. Que corresponden a las que se guardan desde ajustes en catalogos --> frecuencias de Pagos. y en el archivo lib/services/billing_cycle_service.dart vas a modificar la logica en:

final cycleDays = loan.paymentFrequencyDays ?? switch (loan.billingFrequency) {
  'WEEKLY' => 7,
  'DAILY' => 1,
  'BIWEEKLY' => 15,
  _ => 30, // Mensual fijo de 30 días
};
// ...
final nextEnd = nextStart.add(Duration(days: cycleDays - 1));


Para que no tenga harcodeado los dias de la frecuencia si no que tome los dias de la frecuencia que se encuentra en la tabla de la base de datos.

Adicional a esto: Vas a analizar el proyecto completo desde principio a fin, en busca de posibles puntos en los que actualmente se este usando estos dias de las frecuencias de cobros. harcodeados y reemplazalos para que leaa y funcione con los dias de las frecuencias de cobros que se encuentran en la tabla de la base de datos.

Revisa bien todo el flujo completo para asegurse de que todo funcione correctamente y que no se vaya a romper nada, con esto nuevo.


Advertencias a considerar en el desarrollo:
1. No dejar nada harcodeado, como por ejemplo: los colores, ni texto, dias, frecuencias de cobros(pagos), ansolutamente nada.
2. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
3. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
4. Reconstruir el APK, para yo probarlo.
5. si es necesario,  crear nuevos campos en la base de datos para que se guarde la informacion de las frecuencias de cobros(pagos) o cualquier otro dato que se necesite para cumplir con lo pedido, puedes hacerlo, siempre y cuando no afecte a la funcionalidad existente.
6. Asegurate de que lo nuevo que hagas, funcione para multiIdiomas.







**Siguiente mejora**
/* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:
En pantalla Nuevo prestamo, actualmente estas mapeando las frecuencias de cobros(pagos) que se encuentran en la tabla de la base de datos, entonces vas a reemplazarlo por un campo de seleccion de frecuencia de cobros(pagos) para esto crea una nueva pantalla(vista) que se encargue de mostrar las frecuencias de cobros(pagos) que se encuentran en la tabla de la base de datos y que tenga sistema de busqueda y ordenamiento. 


Advertencias a considerar en el desarrollo:
1. No dejar nada harcodeado, como por ejemplo: los colores, ni texto, dias, frecuencias de cobros(pagos), ansolutamente nada.
2. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
3. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
4. si es necesario,  crear nuevos campos en la base de datos para que se guarde la informacion de las frecuencias de cobros(pagos) o cualquier otro dato que se necesite para cumplir con lo pedido, puedes hacerlo, siempre y cuando no afecte a la funcionalidad existente.
5. Asegurate de que lo nuevo que hagas, funcione para multiIdiomas.
6. Reconstruir el APK, para yo probarlo.




**Error**

/* 09 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

en las pruebas al crear un prestamo y darle crear prestamo dio este error:


Error: DatabaseException(table loans has no column named payment_frequency_days (code 1 SQLITE_ERROR[1]): , while compiling: INSERT OR REPLACE INTO loans (loan_id, customer_id, principal_original, principal_balance, monthly_interest_rate, rate_unit, billing_frequency, disbursement_date, end_date, status, closed_at, notes, loan_number, currency_code, applied_exchange_rate, created_at, updated_at, payment_frequency_days) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, NULL, NULL, ?, ?, NULL, ?, ?, ?)) sql 'INSERT OR REPLACE INTO loans (loan_id, customer_id, principal_original, principal_balance, monthly_interest_rate, rate_unit, billing_frequency, disbursement_date, end_date, status, closed_at, notes, loan_number, currency_code, applied_exchange_rate, created_at, updated_at, payment_frequency_days) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, NULL, NULL, ?, ?, NULL, ?, ?, ?)' args [8114c492-3cc2-4def-b2fd-692ee6796826, 6e719c70-4e63-492f-b2d1-d7518a370910, 10000.0, 10000.0, 10.0, MONTHLY, MONTHLY, 2026-01-01, ACTIVE, 1, NIO, 2026-01-09T21:27:20.347074, 2026-01-09T21:27:20.348385, 30]




Revisa bien todo el flujo completo para asegurse de que todo funcione correctamente y que no se vaya a romper nada, con esto nuevo. Asegurate de aumentar la version, agregar los nuevos campos en la base de datos.













**Fix encontrado**

/*10  enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

Escenario en flujo del prestamo:
Caso: Monto de la cuotas vencidas y pendientes, no estan siendo bien calculadas.

Datos del prestamo:

1. Prestamo por 10,000 en moneda NIO.
2. fecha de desembolso 01-12-2025
3. El app genero 2 ciclos vencidos y 1 corriendo.(esto esta correcto)
4. fecha actual 08-01-2026
5. Interes=10%
6. Frecuencia=Quincenal
7. valor de cada cuota vencida 500 NIO



¿Que ocurre?
Sucede que el sistema en vez de mostrar los 500 NIO , que corresponde a cada una de las cuotas, esta mostrando un valor de 499.95 en todas las cuotas, tanto las vencidas como las pendiente.

Esto estaba bien, pero ahorita con el últomo cambio que hisistes, que consiste en leer las frecuencias de pago(cobro) desde la base de datos, desde ahi esta sucediento esto.

Revisa bien las causas de este caso y aplica las mejoras de la mejor forma correcta.

¿que no debes hacer?

Advertencias a considerar en el desarrollo:
1. No dejar nada harcodeado, como por ejemplo: los colores, ni texto, dias, frecuencias de cobros(pagos), ansolutamente nada.
2. No cuadrar o hacer que este escenario salga correcto(harcodeado).
3. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
4. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
5. Asegurate de que lo nuevo que hagas, funcione para multiIdiomas.
6. Reconstruir el APK, para yo probarlo.









**Fix encontrado**

/*10  enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1:

Escenario en flujo del prestamo:
Caso: Recibos no actualiza el saldo restante, cuando se cancela el crédito.

Datos del prestamo:

1. Prestamo por 200 en moneda USD.
2. fecha de desembolso 01-12-2025
3. El app genero 1 ciclos vencidos y 1 corriendo.(esto esta correcto)
4. fecha actual 10-01-2026
5. Interes=10%
6. Frecuencia=Mensual
7. valor de cada cuota vencida 20 USD



¿Que ocurre?
Se realizo 2 abonos 10 USD cada UNO, y fueron aplicados correctamente , los recibos segui diciendo que quedaba un saldo de 200 USD de capital. Despues se procedio a cencelar el prestamo con 207.33, que fue el monto propuesto por el sistema ya que la segundo cliclo es proporcional. y se procedio a cencelar, y en el recibo la distribucion se hace correctamente dice: 7.33 de intereses y 200 de capital, pero en texto que dice : Saldo Restante, sigue disiendo 200 USD. eso esta mal, por que ese dato debe irse actualizando cada vez que se haga un pago, siempre y cuando haya existido un abono al capital.



Advertencias a considerar en el desarrollo:
1. No dejar nada harcodeado, como por ejemplo: los colores, ni texto, dias, frecuencias de cobros(pagos), ansolutamente nada.
2. No cuadrar o hacer que este escenario salga correcto(harcodeado).
3. Hacer pruebas del flujo completo para asegurse de que todo funcione correctamente.
4. Considerar afectaciones en el flujo existente y hacer los ajustes necesarios.
5. Asegurate de que lo nuevo que hagas, funcione para multiIdiomas.
6. NO harcodear monedas, ya que el sistema es multimonedas.
7. Reconstruir el APK, para yo probarlo.

**listo**

























































**Posteriorio**


**Siguiente mejora**
**10 enero 2026**

Antes de cualquier mejora, debes revisar bien el archivo .antigravityrules.md y analizar bien todo el proyecto para entender hasta que punto esta ya desarrollado, despues analizar el nuevo querimiento y indentificar que afecta y asegurarte de que no rompas nada.



Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo .antigravityrules.md y apóyate del MCP de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

CASO 1: Implementar “Planes de Pago” (Planes de Préstamo) para creación rápida de préstamos.

Objetivo de negocio

Se debe implementar una nueva parametrización llamada “Planes de Pago” (o “Planes de Préstamo”), donde el prestamista pueda definir planes preconfigurados (tasa, plazo, frecuencia, moneda, límites, etc.).
Cuando el prestamista seleccione un plan al crear un préstamo, lo único que debe ingresar es el monto a prestar (capital).

El sistema debe aplicar automáticamente el resto de valores del plan y generar los ciclos con la lógica existente (lazy), sin romper el flujo actual.

1) Nuevas pantallas en Ajustes
1.1) Ajustes → Catálogos → Planes de Pago

Crear una nueva pantalla para administrar planes con opciones:

1. Nuevo
2. Editar
3. Eliminar
4. Activar / Desactivar


**Validaciones en Planes:**

1. No se puede eliminar un plan si existe al menos un préstamo activo asociado a ese plan.

2. No se puede desactivar un plan si existe al menos un préstamo activo asociado a ese plan.



**2) Datos que debe tener cada Plan de Pago**

Cada plan debe guardar al menos:

Nombre del plan (obligatorio)

Frecuencia de pago por defecto (obligatorio)

Debe referenciar el catálogo existente de Frecuencias de Pago (tabla ya creada) y utilizar sus intervalDays.

Plazo del plan (Cantidad de cuotas) (obligatorio)

Este valor define cuántos ciclos “máximo” debe tener el préstamo cuando se crea con plan.

Tasa de interés mensual (%) (obligatorio)

Moneda base del plan (obligatorio)

Permitir cambiar moneda al crear préstamo (sí/no, obligatorio)

Monto mínimo (obligatorio)

Monto máximo (obligatorio)

Distribuir capital + interés en las cuotas (sí/no, obligatorio)

Esta es la diferencia principal del plan: si está activo, cada cuota debe contemplar capital + interés (según reglas definidas abajo).

Periodo inicia al desembolsar (sí/no, obligatorio)

Si está ACTIVO: al crear un préstamo con plan, la Fecha de Desembolso debe tomarse automáticamente (por defecto la fecha actual), porque el plan “inicia al desembolsar”.

Si está INACTIVO: al crear un préstamo con plan, el sistema debe exigir que el prestamista seleccione manualmente la Fecha de Desembolso (fecha efectiva del préstamo) usando el campo existente en la interfaz. Esta fecha será la base para calcular cuotas y vencimientos.

Aplica a clientes con categoría (opcional)

Si el plan se restringe a categorías específicas, solo debe estar disponible al crear préstamos para clientes que coincidan.


**3) Crear Préstamo: integrar Plan de Pago sin romper flujo actual**

3.1) Nuevo campo en “Nuevo Préstamo”

En la pantalla Nuevo Préstamo, agregar arriba un selector:

Plan de Pago (Opcional)

Comportamiento:

Si el usuario NO selecciona plan:

El flujo actual se mantiene exactamente igual (préstamo “abierto”).

El usuario selecciona frecuencia y llena los campos manualmente como siempre.

Si el usuario SÍ selecciona plan:

El sistema debe autocompletar y bloquear (o dejar solo lectura) estos campos:

Frecuencia de cobro (desde plan)

Tasa mensual (desde plan)

Moneda (desde plan, salvo que el plan permita cambiar)

Cualquier regla adicional del plan

El usuario solo ingresa:

Monto del préstamo (Capital)

3.2) Manejo de Fechas en UI cuando hay Plan

El campo Fecha de Desembolso ya existe en la interfaz:

Si el plan tiene “Periodo inicia al desembolsar = Activo”, la fecha debe venir prellenada automáticamente (por defecto “hoy”), ya que el préstamo inicia al desembolsar.

Si el plan tiene “Periodo inicia al desembolsar = Inactivo”, la fecha de desembolso debe ser obligatoria y el usuario debe seleccionarla manualmente.

El campo Fecha Fin (Opcional) que hoy existe como informativo:

Cuando el préstamo se cree con Plan de Pago, esta Fecha Fin debe autocompletarse automáticamente según el plan (plazo + frecuencia + fecha de desembolso efectiva), porque el plan sí tiene un final definido.

Asegurar que el cálculo de Fecha Fin se base en intervalos fijos en días (coherente con el sistema actual).

Validaciones al crear con plan:

El monto debe estar entre monto mínimo y máximo del plan.

Si el plan aplica a categorías, validar que el cliente cumple.

Validar que exista Fecha de Desembolso efectiva según la regla del plan.

4) Base de datos y “snapshot” de parámetros del plan en el préstamo
4.1) Nueva tabla: Planes de Pago

Crear la entidad/tabla para almacenar los planes con todos los campos del punto 2.

4.2) Modificar la entidad/tabla de Préstamos

Al crear un préstamo con plan, el préstamo debe guardar un “snapshot” de parámetros para no depender de cambios futuros del plan, incluyendo como mínimo:

planId (nullable)

paymentFrequencyId

paymentFrequencyDays (copiado desde la frecuencia seleccionada)

planInstallmentsTotal (cantidad de cuotas del plan)

interestRateMonthly (tasa mensual aplicada)

distributeCapitalAndInterest (sí/no)

startDate (fecha desembolso efectiva)

endDateCalculated (fecha fin calculada del plan, que también se refleja en UI)

moneda aplicada y flags necesarios

5) Generación de ciclos: adaptar billing_cycle_service.dart para soportar préstamos con plan

Actualmente el sistema genera ciclos con lógica lazy en base a:

startDate

cycleDays (intervalos fijos)

“hoy”

Requerimiento nuevo:

Para préstamos sin plan, se mantiene:

Generar ciclos hasta hoy, igual que ahora.

Para préstamos con plan, se debe:

Reglas oficiales (blindaje del algoritmo, coherente con el catálogo de frecuencias):

La Frecuencia de pago siempre se define por paymentFrequencyDays (intervalDays) desde el catálogo.

Se debe trabajar con estándar comercial:

1 mes = 30 días

1 año = 365 días

El número de ciclos del plan debe ser calculable y consistente con lo anterior.

Calcular una fecha fin del plan:

endDateCalculated = startDate + (planInstallmentsTotal * paymentFrequencyDays) - 1 día
(El “- 1 día” es obligatorio para que la Fecha Fin sea consistente con la lógica actual donde el ciclo termina en start + (cycleDays - 1).)

Cambiar el tope de generación:

tope = min(hoy, endDateCalculated)

Generar ciclos solo hasta ese tope, sin sobrepasarlo (si el último ciclo excede el tope, debe recortarse para terminar exactamente en endDateCalculated).

Distribución capital + interés (solo si el plan lo indica)

Cuando distributeCapitalAndInterest == true:

Regla de negocio del prestamista (interés add-on por plazo):

El interés no se calcula por ciclo; primero se calcula el interés total del plazo y luego se distribuye entre los ciclos.

Calcular el interés total del plazo usando la regla de negocio:

interesTotal = capital * tasaMensual * mesesEquivalentes

Donde mesesEquivalentes debe ser coherente con intervalos fijos:

mesesEquivalentes = (planInstallmentsTotal * paymentFrequencyDays) / 30
(Usar 30 como estándar comercial, coherente con tu “mensual = 30 días”)

Total a pagar:

total = capital + interesTotal

Cantidad de ciclos:

ciclosTotales = planInstallmentsTotal
(Se distribuye el total entre esa cantidad de ciclos.)

Monto esperado por ciclo:

esperadoPorCiclo = total / ciclosTotales

Asegurar que el redondeo no deje diferencias:

Ajustar el último ciclo para que la suma total cierre exacta.

Importante:

Esta lógica NO debe afectar préstamos sin plan.

Actualmente los ciclos en el sistema manejan “Esperado/Pendiente” en términos de interés (interestExpected/interestPending).
Para préstamos con plan y con distribución activa, se debe soportar que el ciclo maneje también el “Esperado/Pendiente” de la cuota total (capital + interés) sin romper el flujo tradicional.
En otras palabras:

Préstamos SIN plan deben seguir usando los ciclos como hoy (interés por ciclo).

Préstamos CON plan + distribución activa deben permitir ciclos con cuota total por ciclo, manteniendo compatibilidad con el modelo existente (puede requerir nuevos campos en la BD/entidad de ciclos).

Los ciclos “Esperado/Pendiente” deben seguir mostrándose como hoy en el detalle del préstamo.



6) Registrar Pago: ajustar comportamiento solo para préstamos con Plan (sin romper el flujo actual)

La pantalla Registrar Pago debe mantenerse igual para préstamos sin plan (flujo actual), conservando exactamente las opciones existentes como:

1. Mixto
2. Solo Interés
3. Solo Capital
4. Cancelar
5. Recuperar

6.1 Detección del escenario “Plan con cuotas distribuidas”

Al entrar a Registrar Pago, el sistema debe detectar si el préstamo cumple ambas condiciones:

Fue creado con Plan de Pago (tiene planId o equivalente).

El plan tiene activa la opción “Distribuir capital + interés en las cuotas”.

6.2 Comportamiento UI cuando aplica Plan con cuotas distribuidas

Si el préstamo cumple esas dos condiciones:

Deshabilitar (enable = false) los botones de tipo de pago que hoy existen como:

Mixto

Solo Interés

Solo Capital, etc.

(Mantener disponibles Cancelar y Recuperar; si ya tienen validaciones, respetarlas.)

En lugar de seleccionar tipo de pago, el sistema debe entrar en un modo de pago “Cuota del Plan” (automático):

Identificar la cuota/ciclo vigente o el más vencido pendiente.

Tomar el monto esperado de esa cuota (que ya incluye capital + interés por distribución del plan).

Precargar automáticamente el campo Monto Pago con ese valor.

El campo Monto Pago debe permitir edición manual para soportar:

Pago parcial: el usuario puede bajar el monto.

Pago de más: el usuario puede aumentar el monto.

Blindaje adicional para que no se rompa la lógica actual:

En este modo “Cuota del Plan”, el pago debe aplicarse internamente reutilizando la lógica existente (equivalente a un pago tipo “Mixto” automático), sin inventar reglas nuevas.
La diferencia es que el usuario no elige el tipo; el sistema aplica el pago a la cuota correspondiente usando el motor actual.

6.3 Reglas de negocio para “Parcial” y “De más”

Para pagos parciales o de más, se debe reutilizar la lógica existente sin inventar nuevas reglas:

Si es parcial:
Guardar el abono y actualizar los saldos y el estado del ciclo según las reglas actuales (ej. ciclo queda pendiente con saldo restante).

Si es de más:
Aplicar el excedente a la siguiente cuota/ciclo pendiente, utilizando la misma lógica existente que ya redistribuye el excedente.

6.4 Compatibilidad y no regresión

Si el préstamo no fue creado con plan, o el plan no distribuye capital + interés:

La pantalla debe comportarse exactamente igual que hoy, sin cambios en UI ni en reglas.

Se deben realizar pruebas de:

Plan con cuota completa.

Plan con pago parcial.

Plan con pago de más (excedente a la siguiente cuota).

Préstamos tradicionales (sin plan) para asegurar que no se rompió nada.

Advertencias a considerar en el desarrollo

No dejar nada hardcodeado (textos, etiquetas, colores, reglas, etc.). Todo debe venir de configuración, catálogos o localización.

Hacer pruebas del flujo completo:

Préstamo sin plan (flujo actual)

Préstamo con plan (nuevo flujo)

Pagos (todos los tipos) para ambos casos

Considerar afectaciones en el flujo existente y hacer los ajustes necesarios sin romper funcionalidad.

Si es necesario crear nuevos campos/tablas para soportar el plan, puedes hacerlo, siempre y cuando no afecte la funcionalidad existente.

**1**








Asegurar que todo lo nuevo funcione con multi-idiomas.

Reconstruir el APK para que yo lo pruebe.



Haz lo siguiente:

vas a dejar los campos de la pantalla Nuevo Plan de Pago de la siguiente forma:

Nombre del plan
plazo:Unidad de ..., Plazo
Frecuencia
total de cuotas
el resto dejarlo a como esta y agerga esta parte que no lo agregastes: Aplica a clientes con categoría (opcional)







Realiza las siguientes mejoras en pantalla de nuevo plan de pago:

1. esta opcion : plica a clientes con categoría (opcional) debe ser un tuggle y solo si el usuario la activa, vas a mostrar un campo de seleccion de categoria para que el usuario, pueda seleccionar del catalogo de categorias, la categoria que desea aplicar al plan, solo puede seleccionar 1 categoria.

2. en gestion de monedas, el campo moneda no debes harcodear nada, debe ser un campo que permita seleccionar la moneda de la base de datos. tal y a como se hace en la pantalla de nuevo prestamo.

3. Nungun campo en que se tenga que digitar tenes que ponerle texto , actulmente por ejemplo el campo Plazo tiene harcodeadi un numero 12, los campos de maximo y minimo tienen cantidades, quita eso y en todo caso lo que podes poner es un placeholder no un texto, que el usuario tenaga que quitar.

4. La pantalla no la mostre como una modal, mostrala como pantalla normal




Debido a que este nuveo requerimiento es bastante grande, dividilo en sprint (entregables) que se puedan probar por separado, para irnos asegurando de que lo que vaya desarrollandose vaya funcionando y  que no rompa nada.



seguiremos en el sprint 2, por que no se  ha hecho a como se solicito en el requerimiento, ya tenes el nombre del plan , la frecuencia, pero falta el plazo




Yo no te pedi nada de simulacion, solo te dije que el numero de cuotas no se esta calculando correctamente, ejemplo: seleccione Frecuencia=Mensual , plazo= 3meses, Unidades=SEMANAS, al seleccionar esos 3 campos el campo de cuotas se devio calculado automaticamente y haber puesto 12 , PERO NO HACE NADA















**refinamiento**

/*12  enero 2026 */

Tomate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Y apoyate del MCP de flutter para resolver los errores que aparezcan, asegurate de cumplir con las rules descritas en el archivo .antigravityrules .

CASO 1:

Escenario en flujo del prestamo con planes de pagos:
Caso: Sprint 4 no cumple con lo esperado en las pruebas realizadas por QA.


**Datos del plan de pago creado:**
Nombre del plan de pago: Iniciantes
Plazo=3
Unidad de plazo=Meses
Frecuencia de cobro=Quincenal(15 días)
Total de cuotas=6
Moneda del prestamo=NIO
Tasa de interes=10%
Monto mínimo=1000
Monto máximo=10000  
Permitir cambio de moneda=no
Distribuir capital e interes en cuotas niveladas=si
El periodo inicia en desembolso=si
Aplica a clientes con categoría (opcional)=Nuevos



**Datos del prestamo a la hora  de crearlo:**

1. Se selecciono el plan de pago "Iniciantes"
2. se logro ver que se cargo automaticamente el interes del plan de pago, Frecuencia de pago, fecha de desembolso  y fecha fin 
3. se procedio a digitar el monto por 10,000
4. se procedio a crear el prestamo

**Validaciones**
1. El prestamo se creo correctamente(Cumple con lo esperado)
2. se procedio a revisar el detalle del prestamo en pantalla "Detalle del Préstamo" y se observo que solo se genero un ciclo con monto =500 NIO (No cumple con lo esperado)

**Que se esperaba**
1. se esperaba que el sistema fuera capaz de generar los ciclos de manera correcta, en este escenario la cantidad de ciclos es de 6 quotas
2. Se espera que el sistema distribuya el capital y el interes de manera correcta, en caso de que el plan de pago tenga activa la opcion "Distribuir capital e interes en cuotas niveladas=si"
3. se espera que el sistema bloque la edición del campo de interes, cuando la opción :"Permitir cambio de moneda=no" este en NO, CASO CONTRARIO DEBE PERMITIR LA EDICION DEL CAMPO DE INTERES.(Actualmente no cumple con lo esperado) 
4. se espera que el sistema no permita cambiar la moneda, cuando la opción :"Permitir cambio de moneda=no" este en NO, CASO CONTRARIO DEBE PERMITIR LA EDICION DEL CAMPO DE INTERES. (Actualmente no cumple con lo esperado)
5. se espera que si la opción "Distribuir capital e interes en cuotas niveladas=NO" este en NO, el sistema se debe comportar como un prestamo tradicional abierto a como funcionaba antes de esta nueva implementación. (Actualmente no cumple con lo esperado)
6. Se espera que el sistema valide que el monto digitado este ente los montos minimo y maximo del plan de pago. (esto si cumple con lo esperado). (Mas sin embargo debes mejorar el mensaje que se le muestra al usuario, actualmente aparece un mensaje tipo bandera, debes cambiarlo por un mensaje de tipo alerta y que sea mediante un dialogo con un solo botón que se llamen OK)
7. SE espera que el sistema valide la categoria de los clientes, para el caso donde la opcion Aplica a clientes con categoría (opcional), este activado.(Actualmente no cumple con lo esperado)

















**refinamiento**

/*12  enero 2026 */

Tomate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Y apoyate del MCP de flutter para resolver los errores que aparezcan, asegurate de cumplir con las rules descritas en el archivo .antigravityrules .

CASO 1:

Escenario en flujo del prestamo con planes de pagos:
Caso: Sprint 4 Distribución de capital mas intereses en las cuotas, no esta funcionando.


**Datos del plan de pago creado:**
Nombre del plan de pago: Iniciantes
Plazo=3
Unidad de plazo=Meses
Frecuencia de cobro=Quincenal(15 días)
Total de cuotas=6
Moneda del prestamo=NIO
Tasa de interes=10%
Monto mínimo=1000
Monto máximo=10000  
Permitir cambio de moneda=no
Distribuir capital e interes en cuotas niveladas=si
El periodo inicia en desembolso=si
Aplica a clientes con categoría (opcional)=Nuevos



**Datos del prestamo a la hora  de crearlo:**

1. Se selecciono el plan de pago "Iniciantes"
2. se logro ver que se cargo automaticamente el interes del plan de pago, Frecuencia de pago, fecha de desembolso  y fecha fin 
3. se procedio a digitar el monto por 10,000
4. se procedio a crear el prestamo

**Validaciones**
1. El prestamo se creo correctamente(Cumple con lo esperado)
2. se procedio a revisar el detalle del prestamo en pantalla "Detalle del Préstamo" y se observo que solo se genero un ciclo con monto =500 NIO (No cumple con lo esperado)

**Que se esperaba**
1. se esperaba que el sistema fuera capaz de generar los ciclos de manera correcta, en este escenario la cantidad de ciclos es de 6 quotas
2. Se espera que el sistema distribuya el capital y el interes de manera correcta, en caso de que el plan de pago tenga activa la opcion "Distribuir capital e interes en cuotas niveladas=si"
3. se espera que el sistema bloque la edición del campo de interes, cuando la opción :"Permitir cambio de moneda=no" este en NO, CASO CONTRARIO DEBE PERMITIR LA EDICION DEL CAMPO DE INTERES.(Actualmente no cumple con lo esperado) 
4. se espera que el sistema no permita cambiar la moneda, cuando la opción :"Permitir cambio de moneda=no" este en NO, CASO CONTRARIO DEBE PERMITIR LA EDICION DEL CAMPO DE INTERES. (Actualmente no cumple con lo esperado)
5. se espera que si la opción "Distribuir capital e interes en cuotas niveladas=NO" este en NO, el sistema se debe comportar como un prestamo tradicional abierto a como funcionaba antes de esta nueva implementación. (Actualmente no cumple con lo esperado)
6. Se espera que el sistema valide que el monto digitado este ente los montos minimo y maximo del plan de pago. (esto si cumple con lo esperado). (Mas sin embargo debes mejorar el mensaje que se le muestra al usuario, actualmente aparece un mensaje tipo bandera, debes cambiarlo por un mensaje de tipo alerta y que sea mediante un dialogo con un solo botón que se llamen OK)
7. SE espera que el sistema valide la categoria de los clientes, para el caso donde la opcion Aplica a clientes con categoría (opcional), este activado.(Actualmente no cumple con lo esperado)






















**Refinamiento**
/*12 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

CASO 1
Escenario en flujo del préstamo con Planes de Pago

Caso: Sprint 4 – Distribución de capital + intereses en las cuotas no está funcionando.

Datos del plan de pago creado

Nombre del plan de pago: Iniciantes
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos


**Validaciones (lo observado en QA)**

1. El préstamo se creó correctamente (cumple).

2. En Detalle del Préstamo, el sistema sí generó las 6 cuotas/ciclos (cumple).

**Problema principal**: cada cuota quedó con Esperado = 500.00 (y Pendiente = 500.00), lo cual evidencia que el sistema está calculando únicamente el interés por cuota y NO está incorporando capital + interés como lo exige el plan cuando la opción “Distribuir capital e interés en cuotas niveladas = Sí” está activa. (No cumple)

**Problema adicional (nuevo hallazgo)**: al entrar a Registrar Pago, el campo Monto Pago se está precargando automáticamente con C$ 13,000.02, lo cual no corresponde al monto esperado por cuota.

En este escenario, el monto por cuota debería ser aproximadamente C$ 2,166.67 (ajustando la última por redondeo).

13,000.02 parece estar tomando el total a pagar completo (o un saldo total) en lugar del monto de la cuota vigente, y además presenta una diferencia de 0.02 que sugiere un problema de redondeo/acumulación. (No cumple)

**Qué se esperaba (agregado por el nuevo hallazgo)**

En préstamos con plan y con “Distribuir capital e interés en cuotas niveladas = Sí”, la pantalla Registrar Pago debe:

1. Identificar la cuota/ciclo vigente o la más vencida pendiente.

2. Precargar el campo Monto Pago con el monto esperado de ESA cuota (cuota total: capital + interés distribuido).

3. Nunca precargar con el total completo del préstamo.

Corregir la causa del 0.02: el total distribuido debe cerrar exacto (ajuste de última cuota / redondeo controlado).




**Refinamiento**
/*12 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

CASO 1
Escenario en flujo del préstamo con Planes de Pago en pantalla "Editar Préstamo".

Caso: 
Cuando se crea un prestamo con un plan de pago y posteriomente se procede a realizar edicion del monto prestado y se le da guardar cambios, en la pantalla "Detalle del Préstamo" se observa solo una cuota.







**Refinamiento**
/*12 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

CASO 1
Escenario: el pago de los prestamos con planes de pago no se esta aplicando correctamente.

Datos del plan de pago creado

Nombre del plan de pago: Iniciantes
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos


**Validaciones (lo observado en QA)**
1. Se ha observado que los ciclos se generan correctamente
2. Los montos de las cuotas se distribuyen correctamente

**Al pagar**
Cuando se realiza el primer pago, el sistema carga el monto de cuota correspondiente y eso esta correcto, pero al aplicar el pago, el sistema me esta cancelando 4 cuotas y abonando a la siguiente cuota, lo cual no es correcto. se observa que el sistema esta suponiendo que la cuota es de 500 cuando es de 2166.67  

Revisar bien todo el proyecto en buscas de este tipo decaso, recordad que ahora tenemos 2 tipos de prestamos 1)el tradicional que ya teniamos y 2)el nuevo que esta usando plan de pago. Por tanto hay que revisar todo el proyecto incluyendo reporteria para indetificar donde hay que aplicar mejoras para que se indentifique que tipo de prestamos es y en base  a eso , mostrar y aplicar la logica correcta para el prestamo . 



**Refinamiento**
/*12 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

CASO 1
Escenario: el pago de los prestamos con planes de pago no se esta aplicando correctamente.

Datos del plan de pago creado

Nombre del plan de pago: Iniciantes
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Que pasa cuando se realiza un pago**

1. se procedio a realizar el pago por un monto de 2166.67, lo cual es correcto. pero al registrar el pago. se observo que en la pantalla de detalle del prestamo, los montos sufren una transformacion, la cual es erronea, al parecer el sistema esta volviendo a redistribuir las cuotas, suponiendo que el monto es de 500 cuando es de 2166.67 , esto lo podemos comprabar si miramos el historial de pago, en el podemos ver que el pago fue de 2166.67, pero se hicieron 4 abonos de 500 y uno de 1666.67 ; eso esta mal, revisar ese punto y asegurarse de que todo el flujo se este aplicando correctamente ambos modo de prestamos. 






**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

CASO 1
Escenario: Pantalla de Nuevo plan de pago, no tiene validaciones de campos vacios y el nombre de la pantalla no es multi idiomas.


Que esta pasando:
1. al crear un plan de pago, no se validan los campos vacios.
2. el nombre de la pantalla no es multi idiomas.

Uno de los errores que se visualiza cuando se deja un campo vacio es:
Error: FormatExeption:Invalid number(at character )

tambien cuando se dejan los campos monto maximo y monto minimo vacios, se visualiza errores.

¿Que hacer?

1. se deben validar los campos como : nombre del plan, plazo, unidad de plazo, frecuencia de cobro, total de cuotas, moneda del prestamo, tasa de interes, estos campos son obligatorios, actualmente se puede guardar un plan de pago con campos como el nombre del plan vacio y eso no es correcto.

2. para el caso de los monto maximo y minimo, como  son campos opcionales , se debe asegurar de que si se dejan vacios no de error a la hora de guardar el plan de pago, actualmente si se dejan vacios, se visualiza error.

3. revisar que otro caso podemos tener ahi que podemos mejorar , sin romper lo que ya existe.





**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo .antigravityrules.md.

**CASO 1**
Escenario:Pantalla detalle del préstamo, esta mostrando inconsistencia en el campo "pendiente".

**Datos del plan de pago creado**

Nombre del plan de pago: Nuevo
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Datos del prestamo**

se selecciono el plan de pago "Nuevo" y se dio guardar prestamo, con un monto de 10,000 NIO

**Pantalla Detalle del Préstamo**
1. Se visualizo que se generaron 6 cuotas(esto es correcto)
2. en los campos vence(la fecha son correctas), Esperado(los datos son correctos), Pendiente(los datos son correctos).
3. se observo que cada ciclo(cuota) espera 2,166.67 y en pendiente tambien a ecepcion de la ultima cuota que es de 2,166.65 por tema de ajustes (esto esta correcto)

**Al realizar un primer pago**
1. Al aplicar un primer pago de la cuota numero 1, se visualiza que cancela correctamente los intereses y el capital de la cuota 1, y en el campo "Pendiente" lo deja en 0 y en historia de pago se puede observar que se cobro 500 de intereses y 1666.67 de capital (esto esta correcto)
2. Al aplicar el segundo pago de la cuota numero 2, se puede visualizar que hay un error, ya que, el campo "Pendiente" no lo deja en 0, si no que lo deja con un valor pendiente de 1,166.67 al parecer a ese campo solo aplico el interes y no el capital, cabe mencionar que en el historial de pago se puede observar que se cobro 500 de intereses y 1666.67 de capital.

**Que hacer**
1. Analizar bien el flujo de pagos para los creditos con plan de pago, asegurarse de que se comporte de la forma correcta.

2. Realizar pruebas adicionales para los creditos con plan de pago, asegurarse de que todo funcione correctamente.

3. Tomar el mismo escenario y realizar pruebas, realizar pagos de cuotas completas y parciales hasta llegar a la cancelacion total del prestamo, para ver como se comporta el sistema y que funcione correctamente. en caso de que salga alguna incosistencia en los datos de visualizacion o datos de la base de datos, corregirlo de inmediatos.

4. solo si las pruebas fueron exitosas y todo funcione correctamente, proceder a la reconstruccion del apk, para pasarlo a QA.


**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.

**CASO 1**
Escenario:Pantalla Registrar Pago.


**Datos del plan de pago creado**

Nombre del plan de pago: Nuevo
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Datos del prestamo**
se selecciono el plan de pago "Nuevo" y se dio guardar prestamo, con un monto de 10,000 NIO
**Detalle del prestamo**
1. se crearon 6 cuotas
2. Cada couta es de 2,166.67 (donde 500 son de intereses y 1666.67 de capital)

**Que esta pasando:**
1.  Para el caso de los prestamos con plan de pago, en la pantalla de registrar pago, hay un campo que se llama "Ciclos pendientes", ahi se muestran los ciclos pendientes, y a los vencidos los muestra en color rojo. Para el caso de los prestamos con plan de pago y para el escenario que tenemos donde la cuota es de 2,166.67 (itereses mas capital), esta mostrando 500 , cuando lo correcto es que muestre la suma del interes mas el capital, pero no lo hace, actualmente me muestra solo el interes que para este escenario es de 500.

2. Se ha observado que l punto 6 del requerimiento no se ha implementado, acontinuacion te dejo todo el punto 6 para que lo analisis y lo implementes.

**6) Registrar Pago: ajustar comportamiento solo para préstamos con Plan (sin romper el flujo actual)**

La pantalla Registrar Pago debe mantenerse igual para préstamos sin plan (flujo actual), conservando exactamente las opciones existentes como:

1. Mixto
2. Solo Interés
3. Solo Capital
4. Cancelar
5. Recuperar

6.1 Detección del escenario “Plan con cuotas distribuidas”

Al entrar a Registrar Pago, el sistema debe detectar si el préstamo cumple ambas condiciones:

Fue creado con Plan de Pago (tiene planId o equivalente).

El plan tiene activa la opción “Distribuir capital + interés en las cuotas”.

6.2 Comportamiento UI cuando aplica Plan con cuotas distribuidas

Si el préstamo cumple esas dos condiciones:

Deshabilitar (enable = false) los botones de tipo de pago que hoy existen como:

Mixto

Solo Interés

Solo Capital, etc.

(Mantener disponibles Cancelar y Recuperar; si ya tienen validaciones, respetarlas.)

En lugar de seleccionar tipo de pago, el sistema debe entrar en un modo de pago “Cuota del Plan” (automático):

Identificar la cuota/ciclo vigente o el más vencido pendiente.

Tomar el monto esperado de esa cuota (que ya incluye capital + interés por distribución del plan).

Precargar automáticamente el campo Monto Pago con ese valor.

El campo Monto Pago debe permitir edición manual para soportar:

Pago parcial: el usuario puede bajar el monto.

Pago de más: el usuario puede aumentar el monto.

Blindaje adicional para que no se rompa la lógica actual:

En este modo “Cuota del Plan”, el pago debe aplicarse internamente reutilizando la lógica existente (equivalente a un pago tipo “Mixto” automático), sin inventar reglas nuevas.
La diferencia es que el usuario no elige el tipo; el sistema aplica el pago a la cuota correspondiente usando el motor actual.

6.3 Reglas de negocio para “Parcial” y “De más”

Para pagos parciales o de más, se debe reutilizar la lógica existente sin inventar nuevas reglas:

Si es parcial:
Guardar el abono y actualizar los saldos y el estado del ciclo según las reglas actuales (ej. ciclo queda pendiente con saldo restante).

Si es de más:
Aplicar el excedente a la siguiente cuota/ciclo pendiente, utilizando la misma lógica existente que ya redistribuye el excedente.

6.4 Compatibilidad y no regresión

Si el préstamo no fue creado con plan, o el plan no distribuye capital + interés:

La pantalla debe comportarse exactamente igual que hoy, sin cambios en UI ni en reglas.

Se deben realizar pruebas de:

Plan con cuota completa.

Plan con pago parcial.

Plan con pago de más (excedente a la siguiente cuota).

Préstamos tradicionales (sin plan) para asegurar que no se rompió nada.

Advertencias a considerar en el desarrollo

No dejar nada hardcodeado (textos, etiquetas, colores, reglas, etc.). Todo debe venir de configuración, catálogos o localización.

Hacer pruebas del flujo completo:

Préstamo sin plan (flujo actual)

Préstamo con plan (nuevo flujo)

Pagos (todos los tipos) para ambos casos

Considerar afectaciones en el flujo existente y hacer los ajustes necesarios sin romper funcionalidad.

Si es necesario crear nuevos campos/tablas para soportar el plan, puedes hacerlo, siempre y cuando no afecte la funcionalidad existente.













**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.

**CASO 1**
Escenario:Pantalla Registrar Pago.


**Datos del plan de pago creado**

Nombre del plan de pago: Nuevo
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Datos del prestamo**
se selecciono el plan de pago "Nuevo" y se dio guardar prestamo, con un monto de 10,000 NIO
**Detalle del prestamo**
1. se crearon 6 cuotas
2. Cada couta es de 2,166.67 (donde 500 son de intereses y 1666.67 de capital)

**Que esta pasando:**
1. Se aplicaron 2 pagos de las 2 primeras cuotas y todo se aplico correctamente.
2. se procedio a realizar un tercer pago por un monto de 3,000 NIO, donde 2166.67 correspondia a la cuota 3 y 833.33 correspondia a la cuota 4. Hasta aca todo se aplico correctamente. El problema esta cuando se quiere aplicar un cuarto pago, a la hora de ir a la pantalla de Registrar Pago y en el campo Monto Pago me deberia de mostrar el monto de la cuota 4 que en este escenario corresponde a 1,333.34 , ya que, en la cuota 3 se hiso un abono parcial de 833.33, ya que, el pago fue por 3,000 NIO. pero el sistema me esta mostrando un valor de : Monto Pago=2,166.67 , no esta considerando el abono que se hizo en la cuota 3. Esto esta ocurriendo sin importar en que cuota se haga un abono parcial o de mas o de menos.

**Que deberia pasar:**
1. El sistema deberia de mostrar el monto de la cuota y considerar si ya tiene abonos parciales o de mas o de menos.

**Revisar bien este caso**
1. Asegurate de que este comportamiento sea corregido y que no se este replicando en los recibos u otros pantallas o reportes.




**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.

**CASO 1**
Escenario:Pantalla Registrar Pago.


**Datos del plan de pago creado**

Nombre del plan de pago: Nuevo
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Datos del prestamo**
se selecciono el plan de pago "Nuevo" y se dio guardar prestamo, con un monto de 10,000 NIO
**Detalle del prestamo**
1. se crearon 6 cuotas
2. Cada couta es de 2,166.67 (donde 500 son de intereses y 1666.67 de capital)

**Que esta pasando:**
1. Se aplico pago a cada una de las 6 cuotas una a una y en la ultima cuota, salto un mensaje que dice: 
"
Mensaje 1 (popup): “Advertencia”
Monto Otorgado: (C$ 2,166.65) > (C$ 1,666.65). ¿Desea continuar con el préstamo de todas formas?
Botones: Cancelar | Continuar"

despues de presionar "Confirmar" , muestra este otro mensaje: 

"Mensaje 2 (popup): “Confirmar Pago”
Monto del Pago: C$ 2,166.65
Cliente: pedro
• A capital: C$ 1,666.65
Botones: Cancelar | Confirmar"


Revisar bien la logica implementada en este caso.

**Otra cosa que pasa**
cuando elimino los pagos desde ajustes y vuelvo a la pantalla detalle del prestamo, el campo Pendiente me sigue saliendo en 0, cuando lo correcto es que muestre el monto de las cuotas, ya que, he borrado los pagos del prestamo.















**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.


1. En Ajustes agrega una nueva politica de negocio que indique, cual sera la prioridad de recuperacion para el caso cuando en la pantalla de Registrar Pago se seleccione la opcion de Recuperar, el prestamista debe configurar si al recuperar se priorizara el capital o el interes. esto servira para el punto 1 descrito mas abajo en el apartado **Que esta pasando:**.




**CASO 1**
Escenario:Pantalla Registrar Pago.

**Datos del plan de pago creado**

Nombre del plan de pago: Nuevo
Plazo = 3
Unidad de plazo = Meses
Frecuencia de cobro = Quincenal (15 días)
Total de cuotas = 6
Moneda del préstamo = NIO
Tasa de interés = 10%
Monto mínimo = 1000
Monto máximo = 10000
Permitir cambio de moneda = No
Distribuir capital e interés en cuotas niveladas = Sí
El período inicia en desembolso = Sí
Aplica a clientes con categoría (opcional) = Nuevos

**Datos del prestamo**
se selecciono el plan de pago "Nuevo" y se dio guardar prestamo, con un monto de 10,000 NIO
**Detalle del prestamo**
1. se crearon 6 cuotas
2. Cada couta es de 2,166.67 (donde 500 son de intereses y 1666.67 de capital)

**Que esta pasando:**
1. En la pantalla de registrar pago, cuando se selecciona el boton "Cancelar" el sistema pone en el campo "Monto Pago" 10,500 , cuando lo correcto para este escenario es 13,000. el sistema debe ser capaz de cobrar los intereses totales mas el capital y eso aplica para prestamos con o sin planes de pagos.


2. En la pantalla de registrar pago, cuando se selecciona el boton "Recuperar" el sistema toma el monto digitado en el campo "monto pago" y lo aplica como si fuera capital. ejemplo: se hizo la recuperacion del prestamo arriba descrito y al seleccionar la opcion Recuperar el sistema puso un valor =10,000  ; eso esta bien, pero se procedio a digitar 12,000, ya que, en este caso puede pasar 2 casos uno en el que el cliente da una cantidad mayor al capital por que quizas quiere pagar algo de intereses y dos en el  que el cliente paga incluso menos del capital entregado, y el sistema debe ser capaz de saber que hacer. ejemplo: para este caso de Recuperacion, el sistema debe leer la politica de negocio que se configuro en ajustes y segun eso debe aplicar la prioridad de recuperacion. 



**Logica a implementar**
1. si la prioridad es el capital y el cliente pago demas y tiene cuotas vencidas, el sistema debe aplicar el sobrante a las cuotas vencidas.
2. si la prioridad es el interes vencido y el cliente pago demas del valor de los intereses vencidos, el sistema debe aplicar el sobrante al capital
3. si la prioridad es el capital y el cliente pago con lo completo del capital entregado , las cuotas se deben de la misma forma en la que se esta tratando actualmente.











**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.


**Esceario** : se hizo un escenario para un prestamo  con monto otorgado de 10,000 NIO y con fecha de sembolo 01-12-25 , con frecuencia de cobro quincenal. el prestamo tenia 2 cuotas vencidas y una cuota por corriendo. 

**ajustes**
en ajustes se configuro la politica de negocio de recuperacion de capital y intereses, y se dejo en prioridad capital.


**Cancelac**
se hizo la recuperacion del prestamo con un monto de 10,600 NIO

**Que esta pasando:**
el sistema si ovedecio la prioridad guardada en ajustes y el sobrante lo abono a las cuotas vencidas, eso lo puedo ver tanto en los recibos como en el historial de pagos.

**a donde esta el error:**
El campo "pendiente" en los ciclos de pagos no se actualiza correctamente, para este ejemplo se devio haber cancelado la primer cuota por 500 NIO y se debio haber aplicado un abono a la segunda cuota por 100 NIO y asi devio haber quedado por cuestiones de auditoria. pero no fue asi, todas las cuotas quedaron con el campo pendiente en 500.00.

**Importante**
1. este escenario sucedio con un prestamo que no tenia plan de pago.
2. esta misma logica se aplica para prestamos con plan de pago, para el caso cuando se seleccione la opcion de recuperar.













**Refinamiento**
/*13 enero 2026 */

Tómate un tiempo para analizar bien los escenarios y resuelve los errores que aparezcan. Apóyate del MCP de Flutter para investigar y corregir la causa raíz, y asegúrate de cumplir con las rules descritas en el archivo @file:.antigravityrules.md.


**CASO 1**
Escenario:Pantalla Registrar Pago.

**Esceario** : se hizo un escenario para un prestamo  con monto otorgado de 10,000 NIO y con fecha de sembolo 01-12-25 , con frecuencia de cobro quincenal. el prestamo tenia 2 cuotas vencidas y una cuota por corriendo. 

**Que pasa**
1. Cuando se selecciona la opcion de cancelar, el sistema debe mostrar el monto total del prestamomas los intereses vencidos mas los intereses parciales en el caso de que exista alguna cuota en estado corriendo y que aun no llegue a su fecha de vencimiento. cabe recarcal que esto ya estaba funcionando correctamente, fue lo primero que se hiso, apenas agregamos el plan de pago ya dejo de funcionar, ya les he dicho que el sistema debe funcionar a como estaba antes, y tambien con la nueva forma que son los planes de pagos.




































**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**
**------------------------------------------>**













**14  enero 2026**
**ESCENARIO 1**
**PLAN DE PRUEBAS FINALES**
**REFINAMIENTO**
**CASOS DE PRUEBAS FUNCIONALES**


Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo @file:.antigravityrules y apóyate del @mcp:dart-mcp-server: de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

No dejes nada harcodeado y lo que vas a hacer que no afecte a las funcionalidades existentes, ya que, tambien tenemos prestamos con planes de pagos y ambos deben funcionar correctamente. para el caso de se necesario que hagas un ajuste en el codigo, asegurate de que el ajuste que hagas no afecte a la funcionalidad de los prestamos con planes de pagos.

**CASO 1:**
**Escenario en flujo del prestamo, para un prestamo sin un plan de pago:**

**Datos del prestamo:**

1. Prestamo por 10,000 en moneda NIO.
2. fecha de desembolso 01-12-2025
3. fecha actual 14-01-2026
4. Interes=10%
5. Frecuencia=Quincenal
6. valor de cada cuota vencida 500 NIO
7. valor de cada cuota corriendo 500 NIO 

**Ciclos de pagos, al ir a la pantalla de registrar pago :**
1. Primer ciclo: 01-12-2025 - 15-12-2025 monto de 500 NIO
2. Segundo ciclo: 16-12-2025 - 31-12-2025 monto de 500 NIO
3. Tercer ciclo: 01-01-2026 - 15-01-2026 monto de 466.67 NIO

Nota: Al día 14-01-2026 el tercer ciclo aún no ha vencido, por lo tanto el interés a cobrar debe ser parcial y prorrateado.


**Como deberia de funcionar el calculo si se presiona el boton cancelar:**
la prueba consiste en que si el cliente decide cancelar el prestamo, el sistema debe mostrar el monto total del prestamo mas los intereses vencidos mas los intereses parciales en el caso de que exista alguna cuota en estado corriendo y que aun no llegue a su fecha de vencimiento.

en este escenario lo que se debe cobra es:
capital = 10,000
intereses vencidos = 1,000 (correspondientes a la 2 cuotas vencidas)
intereses parciales =466.67
Total a cancelar= capital + intereses vencidos + intereses parciales, entonces el total a cancelar es 11,466.67 NIO

**Aclaración importante**
El sistema NO debe modificar el valor esperado del ciclo completo (500 NIO).
El valor de 466.67 NIO corresponde únicamente al cálculo parcial para cancelación anticipada.
