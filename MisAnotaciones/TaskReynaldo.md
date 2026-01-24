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










Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo @file:.antigravityrules y apóyate del @mcp:dart-mcp-server: de Flutter para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.


Siguiente mejora

Configuración de Convención Financiera de Intereses (Day Count Convention)
Ubicación: Ajustes → Políticas del Negocio

Objetivo de negocio

El sistema debe permitir que el prestamista defina, desde configuración, cómo se calculan los intereses en el tiempo, sin que exista ninguna regla financiera quemada en el código.

Esta configuración será la autoridad única para todos los cálculos financieros del sistema:

Intereses vencidos

Intereses parciales

Cálculo de cuotas

Cancelaciones anticipadas

Planes de pago

Préstamos tradicionales

El sistema debe adaptarse automáticamente según la política configurada por el prestamista.

1) Nueva sección en Ajustes → Políticas del Negocio

Crear una nueva pantalla:

Ajustes → Políticas del Negocio → Convención Financiera de Intereses

Con los siguientes campos configurables:

1.1 Convención de conteo de días (Day Count Convention)

Selector obligatorio:

30/360 (Estándar comercial)

Actual/360

Actual/365

30/365

(Permitir agregar nuevas convenciones en el futuro)

Este valor define cómo se calcula el interés diario.

1.2 Días por mes

Campo numérico obligatorio.

Ejemplo:

30 (para convención 30/360)

31 (si el prestamista así lo desea)

Este valor NO debe depender del calendario real.

1.3 Días por año

Campo numérico obligatorio.

Ejemplo:

360

365

1.4 Regla de prorrateo

Selector obligatorio:

Prorrateo por días exactos

Prorrateo por proporción del ciclo

(Este valor define cómo se calcula el interés parcial dentro de un ciclo.)

1.5 Política de redondeo monetario

Campos configurables:

Cantidad de decimales (ej. 2, 3, 4)

Tipo de redondeo:

HALF_UP

HALF_EVEN (bancario)

DOWN

UP

2) Reglas obligatorias

Ninguna fórmula financiera puede usar valores quemados como:

30

360

365

15

7

Todos los cálculos deben leer:

Convención seleccionada

Días por mes

Días por año

Regla de prorrateo

Política de redondeo

Desde Ajustes → Políticas del Negocio.

Si el usuario cambia esta configuración, los nuevos préstamos deben usar la nueva política, pero los préstamos existentes deben conservar el snapshot de la política con la que fueron creados.

3) Persistencia en Base de Datos

Crear una nueva tabla o entidad:

BusinessFinancialPolicy

Campos mínimos:

id

dayCountConvention

daysPerMonth

daysPerYear

prorationRule

roundingDecimals

roundingMode

isActive

createdAt

updatedAt

Solo puede existir una política activa a la vez.

4) Snapshot en Préstamos

Al crear un préstamo, se debe copiar la política activa a los campos del préstamo:

loanDayCountConvention

loanDaysPerMonth

loanDaysPerYear

loanProrationRule

loanRoundingDecimals

loanRoundingMode

Esto garantiza que un préstamo nunca cambie su lógica financiera por cambios futuros en configuración.

5) Impacto en el motor financiero

Todo el sistema financiero debe leer estas políticas desde el préstamo, nunca desde constantes.

Esto incluye:

Generación de ciclos

Cálculo de interés

Interés parcial

Cancelación

Planes de pago

Refinanciamientos

Reportes

6) Validaciones

No permitir guardar políticas con valores inconsistentes.

No permitir días por año menores a días por mes * 12.

No permitir valores cero o negativos.

Mostrar advertencia clara cuando se cambie la política.

7) UI / UX

La pantalla debe explicar en texto claro qué hace cada convención.

Debe mostrarse un ejemplo automático de cálculo según la configuración seleccionada.

Debe permitir previsualizar cómo quedaría una cuota ejemplo.

8) Documentación obligatoria

El desarrollador debe:

Documentar la política financiera en el proyecto.

Documentar cómo impacta en el cálculo.

Documentar que no existen reglas quemadas.

Documentar cómo extender nuevas convenciones en el futuro.

Resultado esperado

El sistema deja de tener reglas financieras rígidas y pasa a ser un motor financiero parametrizable, donde:

El prestamista controla la matemática del negocio, no el código.


























REFINAMIENTO – VALIDACIÓN DE LECTURA DE CONVENCIÓN FINANCIERA DESDE AJUSTES
Objetivo

Verificar y garantizar que el sistema lea correctamente la Convención Financiera configurada en Ajustes y que esta política se aplique de forma real y efectiva en todos los cálculos financieros del préstamo, en especial en el cálculo de Cancelar Préstamo.

Contexto

Actualmente, al cambiar la Convención Financiera en:

Ajustes → Políticas del Negocio → Convención Financiera
(ejemplo: 30/360, Actual/360, Actual/365, 30/365)

el resultado del cálculo de cancelación no varía, lo cual indica que:

O la configuración no se está leyendo.

O se está leyendo, pero no se está aplicando.

O el préstamo no está usando correctamente el snapshot de política financiera.

Escenario de Prueba Reproducible
Paso 1

Configurar en Ajustes:

Convención: Actual/365
Regla de prorrateo: Días Exactos
Redondeo: 2 decimales – Hacia Arriba

Guardar configuración.

Paso 2

Crear un préstamo nuevo con:

Capital: 10,000 NIO

Tasa mensual: 10%

Fecha de desembolso: hoy

Paso 3

Ir a la opción Cancelar Préstamo y registrar el total sugerido.

Paso 4

Volver a Ajustes y cambiar la Convención a:

Convención: 30/360

Guardar configuración.

Paso 5

Crear otro préstamo nuevo con los mismos datos.

Paso 6

Ir nuevamente a Cancelar Préstamo.

Resultado Esperado

Los resultados de cancelación deben ser distintos entre ambos préstamos, ya que la convención financiera utilizada es diferente.

Resultado Actual

El sistema muestra el mismo monto en la cancelación sin importar la convención configurada.

Validaciones que se deben realizar en código

El sistema debe validar y documentar:

Que la Convención Financiera se lee desde Ajustes correctamente.

Que dicha política se guarda como snapshot en el préstamo al momento de crearlo.

Que todos los cálculos financieros usan exclusivamente la política almacenada en el préstamo, no valores hardcodeados.

Que no exista ninguna fórmula con:

/360

/365

30

15
sin provenir de la política configurada.

Que el cálculo de:

Interés vencido

Interés parcial

Cancelación total
dependan estrictamente de la política financiera del préstamo.

Regla obligatoria

Ningún cálculo financiero debe usar valores fijos.
Todo debe provenir de la política financiera configurada y del snapshot almacenado en el préstamo.

Objetivo del refinamiento

Garantizar que:

La configuración en Ajustes no sea solo visual.

El sistema sea auditable financieramente.

El comportamiento sea equivalente a un sistema bancario real.












**escenario de prueba**

ESCENARIO A — SIN PLAN — Convención 30/360 — CANCELAR con 2 vencidas + 1 corriendo

1) Ajustes

Ajustes → Políticas del Negocio → Convención Financiera: 30/360

2) Datos del préstamo (sin plan)

Capital: 10,000.00 NIO

Tasa: 10% mensual

Frecuencia: Quincenal (15 días)

Fecha desembolso: 05-12-2025

Fecha actual de prueba: 14-01-2026

Plan de pago: NO

3) Ciclos de pago esperados

Ciclo 1: 05-12-2025 – 19-12-2025 (15 días) → Vencido

Ciclo 2: 20-12-2025 – 03-01-2026 (15 días) → Vencido

Ciclo 3: 04-01-2026 – 18-01-2026 (15 días) → Corriendo (porque hoy 14-01 está dentro)

4) Ir a pagar

Acción: Cancelar (fecha hoy 14-01-2026)

5) Resultado esperado (qué debe mostrar al cancelar)

Con 30/360, la fórmula esperada para interés diario (derivada de 10% mensual) es:

Tasa anual = 10% × 12 = 120% anual

Interés periodo = Capital × 1.20 × (días devengados / 360)

Entonces:

Intereses vencidos: 2 periodos completos de 15 días:

Interés 15 días = 10,000 × 1.20 × (15/360) = 500.00

Vencidos = 2 × 500.00 = 1,000.00

Interés parcial del ciclo corriendo: desde 04-01-2026 hasta 14-01-2026

Días devengados = lo que el sistema defina internamente (esto es justamente lo que hay que validar con tu convención elegida).

Por eso el total esperado debe ser uno de estos, dependiendo de si el motor cuenta 10 o 11 días:

Si son 10 días: parcial = 10,000 × 1.20 × (10/360) = 333.33 → Total cancelar 11,333.33

Si son 11 días: parcial = 10,000 × 1.20 × (11/360) = 366.67 → Total cancelar 11,366.67

Qué valida este escenario

Que 30/360 esté aplicando 360 en el denominador y que el interés por 15 días sea 500.

Que el “parcial” se calcule con la misma convención.

ESCENARIO B — SIN PLAN — Convención Actual/365 — MISMO PRÉSTAMO — CANCELAR (debe dar DIFERENTE)

1) Ajustes

Convención Financiera: Actual/365

2) Datos del préstamo

Exactamente los mismos del Escenario A.

3) Ciclos

Exactamente los mismos del Escenario A.

4) Ir a pagar

Acción: Cancelar

5) Resultado esperado

Interés vencido para 15 días con Actual/365:

Interés 15 días = 10,000 × 1.20 × (15/365) = 493.15

Vencidos (2 ciclos) = 2 × 493.15 = 986.30

Interés parcial (04-01 a 14-01):

Si 10 días: 10,000 × 1.20 × (10/365) = 328.77

Si 11 días: 10,000 × 1.20 × (11/365) = 361.64

Total cancelar esperado:

Con 10 días: 10,000 + 986.30 + 328.77 = 11,315.07

Con 11 días: 10,000 + 986.30 + 361.64 = 11,347.94

Qué valida este escenario

Que al cambiar de 30/360 a Actual/365, el total de “Cancelar” cambie (si no cambia, no está leyendo ajustes o no está aplicando convención).

ESCENARIO C — CON PLAN — Cuotas niveladas capital+interés — ajuste de redondeo (última cuota)

1) Ajustes

Convención Financiera: cualquiera (este escenario es de “cuotas” y redondeo)

2) Datos del plan

Plan: Iniciantes

Plazo: 3 Meses

Frecuencia: Quincenal (15 días)

Total cuotas: 6

Tasa: 10% mensual

Distribuir capital + interés en cuotas niveladas: Sí

3) Datos del préstamo

Seleccionar Plan: Iniciantes

Capital: 10,000.00

Crear préstamo

4) Ciclos de pago esperados

Interés total: 10,000 × 10% × 3 = 3,000

Total: 13,000

6 cuotas: 13,000 / 6 = 2,166.666…

Esperado “a lo bancario” (cierre exacto)

Las cuotas deben sumar exactamente 13,000.00

Ejemplo válido:

Cuotas 1–5 = 2,166.67

Cuota 6 = 2,166.65

No debe quedar 13,000.02

Qué valida este escenario

Que el ajuste por redondeo se haga dinámico en la última cuota.

ESCENARIO D — PRUEBA CLAVE: que los ajustes sí afectan (verificación rápida)

1) Ajustes

Poner Convención: 30/360

2) Préstamo

Usar Escenario A (sin plan)

3) Resultado

Guardar el total “Cancelar”

4) Ajustes

Cambiar Convención: Actual/365

5) Mismo préstamo / misma fecha

Volver a “Cancelar”

6) Resultado esperado

El total debe ser diferente.




Agrega un campo a la tabla de clientes que se llame "lacero" de tipo string y hace la migracion de Sqflite y usa el MCP de dart para apoyarte en el desarrollo, y asegurate de usar la ultima version de la libreria SqfLite, tanto la documentacion como la implementacion y tambien verifica que cuando inicie el app no tenga ningun conflicto con mis tablas
















**Siguiente mejora**
/* 17 enero 2026 */

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA QUE SE ABRE AL SELECCIONAR UN CLIENTE EN CLIENTES**

En la parte de historial de préstamos, el campo que muestra la tasa de interes del préstamo, cuando la tasa es un numero con decimal , ejemplo: 12.40 , el sistema solo muestra la parte entera y no la parde decimal, ese campo debe ser de tipo de decimal para soportar ambos tipos de numeros.


**PANTALLA Detalles del Préstamo**

Aca tenemos el mismo problema, el campo que muestra la tasa de interes del prestamo, cuando la tasa es un numero con decimal , ejemplo: 12.40 , el sistema solo muestra la parte entera y no la parde decimal, ese campo debe ser de tipo de decimal para soportar ambos tipos de numeros.

Repara ambos fix y hay nomas hacete una busqueda en todo el proyecto incluyendo pantallas y reportes en busca de casos similares y corrige todos los problemas relacionado con el tema arriba descrito.












**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

En pantalla Ajuste → apartado políticas del negocio → crear un nuevo campo para que el prestamista pueda definir un número entero, el campo debe llamarse "planificar cobro". Dejar el número 3 por defecto con opciones de incrementar o disminuir.

agrega el icono de informacion y da una explicacion al usuario de que es el campo y que hace, que basicamente este campo sera para que el prestamista pueda definir cuantos dias de antelacion quiere que se le muestre los prestamos que le tocan cobrar en la pantalla "A cobrar".

Agregar multi idioma a esta nueva pantalla.



**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

Crear una consulta SQL que haga lo siguiente: leer todos los préstamos activos y cargar todos aquellos donde la fecha de la próxima cuota esté dentro de los días de antelacion definidos en el campo "planificar cobro".
Ejemplo: si un préstamo A le toca pago los 15 de cada mes y el campo tiene 3, y si pongamos que hoy es 12 entonces no mostrar, pero si hoy fuera 13 o 14 o 15 entonces sí debe mostrarse.



En pantalla "A cobrar" quitar las pestañas Quincena, Mes, y reemplazarlas por una nueva pestaña que se llame "A cobrar" posteriormente se debe cambiar la lógica de carga en esta nueva pestaña, deberá de funcionar de la siguiente forma: cargar todos los préstamos de la consulta SQL creada.

Mantener la pestaña Atrasados y toda su logica.

Quitar el botón de recargar ya que esta pantalla se debe actualizar cada vez que se aga un cambio, y debe ser automático.

Mantener el campo para buscar.
**LISTO**






**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.


Diseñar los siguientes reportes:

1. Nuevo reporte nombrado "Comprobante de Desembolso Con Plan de Pago"(o puedes usar un nommbre mas corto), exclusivamente para todos aquellos prestamos que contegan un plan de pago. 

**Diseño**
1. primer seccion con los datos de la empresa siempre y cuando en Ajustes datos de la empresa esten configurados para mostrarse.
2. Segunda seccion mostrar campos: fecha y hora de impresion, fecha y hora del desembolso,fecha de vencimiento, cliente, dni, monto otorgado, tasa de interes, frecuencia, 
3. Tercera seccion mostrar un detalle de los ciclos de pagos con los siguientes campos: Fecha inicio, fecha fin, a principal, a interes, total.
4. Cuarta seccion, mostrar los datos de las firmas entregado por y recibido por , mas la leyenda configurada y guardada en Ajustes.

**FLUJO**
si el prestamo no tiene plan de pago no mostrar el reporte Comprobante de desembolso que ya existe, si el prestamo tiene plan de pago mostrar el reporte Comprobante de desembolso con plan de pago(que es el nuevo que crearas)

**Mantener flujo del reporte Comprobante de desembolso que ya existe**
ejemplo: Si en ajustes esta configurado para enviar por WharsApp el sistema debe permitir enviar el pdf por whatsApp tal y a como esta el reprote comprobante de desembolso actual.

**Agregar multi idiomas**
1. agregar multi idiomas al reporte Comprobante de desembolso con plan de pago

**NOTA**
1. el reporte nuevo debe tener el mismo tipo de formato que tiene el reporte Comprobante de desembolso  actual.

**LISTO**



















**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.


**MEJORA EN REPORTE DE: "COMPROBANTE DE DESEMBOLSO"**
1. Agregar un nuevo campo debajo del campo Fecha, el nuevo campo debe llamarse "Fecha de la proxima cuota" y debe mostrar la fecha de la proxima cuota del prestamo.

**MEJORA EN REPORTE DE "recibo de pago"**
1. Agregar un nuevo campo llamado "Fecha de la proxima cuota" y debe mostrar la fecha de la proxima cuota del prestamo.

**NOTA:**
Este cambio debe ser aplicado a los recibos sin importar si el prestamo tiene plan de pago o no. y al COMPROBANTE DE DESEMBOLSO que ya existe.

**Agregar multi idiomas**
1. agregar multi idiomas al reporte Comprobante de desembolso con plan de pago

**LISTO**







**Mejora en REPORTE COMPROBANTE DE DESEMBOLSO CON PLAN DE PAGO**
1. El campo Vencimiento no coincide con la fecha de la ultima cuota del plan de pago.

ejemplo: se creao un prestamo con fecha de desembolo el 19-01-26 y en el plan de pago que se le asigno la frecuencia es "Semanal" y plazo a 1 mes, el sistema creo 5 cuotas :

cuota 1 vence el 25-01-26
cuota 2 vence el 01-02-26
cuota 3 vence el 08-02-26
cuota 4 vence el 15-02-26
cuota 5 vence el 22-02-26

Pero en el campo Vencimiento refleja 17-02-26

**NOTA**
1. el campo Vencimiento debe CONCORDAR con la fecha de la ultima cuota del plan de pago.

**ADICIONAL**
1. Quitar back color a la cabezeras de la tabla de los cliclos de pagos.
2. Los textos de la tabla de los cliclos de pagos deben auto ajustarse para que no se desborde el texto, actualmente se esta desbordando el texto.
3. Agrega el campo de la moneda del prestamo.
**LISTO**









**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**RESOLVER EL SIGUIENTE FIX, en prestamos sin plan de pago**


EN LA PANTALLA DE "Detalle de Préstamo" , en los ciclos de cobros CUANDO SE hace un pago el campo fecha proxima cuota que aparece en el recibo de pago, no coincide con las fechas de los ciclos de cobros en la pantalla de detalle de prestamo.

ejemplo: se creo un prestamo hoy 19-01-26, con frecuencia "Quincenal" y sin plan de pago, la fecha de desembolso fue el 01-12-25 y el sistema genero 4 cuotas a la fecha de hoy 19-01-26:

cuota 1 vence el 15-12-25
cuota 2 vence el 30-12-25
cuota 3 vence el 14-01-26
cuota 4 vence el 29-01-26

cuando se cancela la cuota 1, en el recibo de pago aparece como fecha de la proxima cuota 29-12-25, pero en la pantalla de detalle de prestamo aparece como fecha de la proxima cuota la fecha de la cuota 3 que es 14-01-26


**parece estar bien**









**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**MEJORA EN PANTALLA A COBRAR**
1. En la pantalla a cobrar, pestaña A cobrar cada tarjeta que contiene los prestamos a cobrar, deben tener el numero de prestamo, de igual manera en la pestaña Atrasados.

al finalizar reconstruye el apk, para probar.

**LISTO**




**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**APLICAR MEJORA ESTETICA EN PANTALLA DE INICIO**

1.  Pantalla de inicio, reorganizar las tarjetas de la siguiente menera: capital colocado, Ganancias del mes, proyeccion de mes, prestamos vencidos, prestamos activos, clientes activos
2. Actualmente cada tarjeta es demasiado grande, hazla mas comprimida y organiza los textos de cada tarjeta de forma logica 
3. Aplica una especia de efecto moderno a cada tarjeta, que parezca que estan flotando (investiga muy bien en el MCP de dart, para hacer esto de forma que no recargues el sistema, hazlo nativo y dale un toque original y moderno)
4. Toda las tarjetas deben tener un estilo glasmorphism
5. Todo esto que hagas debes contemplarlo para cuando se use el thema Oscuro desde ajustes.





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**APLICAR MEJORA ESTETICA EN PANTALLA DE INICIO**

1. Quita el efecto glasmorphism por que lo que hicistes esta orrendo.
2. la tarjeta capital colocado el texto dentro debe estar de la siguiente forma: 
Capital colocado 
monto de capital de trabajo
aca abajo mostrar el progresbar
3. las demas tarjetas primero deben decir lo que se requiere transmitir y abajo el monto ejemplo:
Ganancias del mes
C$ 4,500

4. Asegurarte de que los textos no se desborden de su lugar , actualmente ocurre eso. las tarjetas y todas las pantallas deden ser completamente flexibles , es decir 100% responsive.





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**APLICAR MEJORA ESTETICA EN PANTALLA DE INICIO**
1. KPI capital colocado : que cubra todo el ancho de la pantalla a como se ve en la imagen.
2. reordena los demas KPI de la misma forma en la que se ve en la imagen.
3. move los iconos de los KPI a como se ve en la imagen.

Nota: la imagen que te muestro es solo un ejemplo nada mas para que te fijes , vas a mantener el color , tipo de textos , y diseño que actualmente tienen.






**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA DE INICIO**
1. el kpi capital colocado el progresbar , ahi hay un texto que indica el porcentaje de progreso ejemplo 20% , te mencione que ese texto debe ir relacionado con el incremento del progressbar , me refiero a que se debe ir moviendo conforme vaya avanzando el progressbar , actualmente no es asi. se va demasiado adelante y debe ir en la punta del incremento. preferible que el texto quede sobre el avance del progressbar.




**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA A Cobrar**
**pestaña a cobrar**
1. en cada tarjeta que s emuestre agregar un campo que indique la fecha que vence la cuota, es decir la fecha de la cuota que se debe pagar. (esto sera muy importante ya que ahi se muestran los prestamos a cobrar , pero como tenemos un parametro en ajustes que hace que aparezcan los prestamos segun los dias de antelacion, es decir si esta en 1 o dos o tres segun lo configure el prestamista, pero no sabemos realmente la fecha que le toca el pago y eso vendra a tener claridad, el prestamista podra darse cuenta que si esta ahi , no necesariamente es por que ya le toque pago si no por que quizas en los dias de antelacion tiene configurado que aparezcan los prestamos a cobrar con varios dias pero ya con ese nuevo campo, podra saber realmente el dia que venece la cuota)

**pestaña atrasados**
2. en la pestaña atrasados, agregar el mismo campo, salvo que aca ese nuveo campo debe mostrar la fecha de la cuota que esta atrasada, pero si el prestamo tiene varias cuotas vencidas, se debe mostrar la fecha de la cuota mas antogua vencida, para que el prestamista pueda saber desde cuando ese prestamo esta atrasado y que debio pagar.


**En Recibos de pago**
1. hacer lo siguiente: agregar un campo que muestre desde que fecha a que fecha se hizo el pago, es decir la fecha de inicio y la fecha de fin del pago y si el prestamo tiene un plan de pago, se debe indicar el numero de la cuota que se esta pagando. ejemplo: 
1. para el caso del prestamo sin plan de pago: Periodo de pago: 2025-01-01 al 2025-01-31
2. para el caso del prestamo con plan de pago: Periodo de pago: 2025-01-01 al 2025-01-31, cuota: 1
**listo**







**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Mejoras**
1. en pantalla a cobra en ambas pestalas el campo nuevo que agregamos que muestra la fecha de la cuota que se debe pagar, veo que cuando la cuota tiene pocos dias vencido dice algo asi:  vencido desde: Hace 6 dias.  eso no debe ser asi, siempre debe msotrar la fecha.

2. en recibo el nuevo campo tiene un salto de linea asi: 

periodo de pago: 2025-01-01-
2025-01-31






**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Mejoras**
1. en recibos hay que agregar una bandera que indique si el pago que se esta efectuando correspondiente a una cuota , es parcial o completa.




**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Pantalla A Cobrar**
1. etengo un prestamo que contiene un plan de pago y en A cobrar me sale ya que la fecha de pago esta proxima , pero en la tarjeta  los campos "Interés esperado" y "Pendiente" no coinciden con los datos de la cuota.

ejemplo: en la pantalla Detalle del prestamo, en ciclos de cobro me sale asi:
vence el 26/1/2026
esperado: C$ 1,076.85
Pendiente: C$ 1,076.85

y en la tarjeta en A cobrar pestaña a cobra me sale :

Interés esperado: C$ 307.62
pendiente: C$ 307.62

eso esta mal.

Revisa bien en la pantalla a cobrar en ambas pestasñas que los datos que se muestran sean los correctos, sin importar si el prestamo tiene plan de pago o no. y busca si esa inconsistencia esta en algun otro lado y lo reparas.





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Pantalla A Cobrar**
1. en esta pantalla debemos crear un caso :

caso 1: prestamo sin plan de pago, debe quedar a como esta actualmente.

caso 2: prestamo con plan de pago, hacer la siguiente logica: ocultar los campos "Interés esperado" y "Pendiente" y mostrar un campo que muestre el valor de la cuota ya que para este caso viene los intereses mas el capital.

**NOTA**
se debe aplicar a ambas pestañas de la pantalla A cobrar, SOlo que en la pestaña atrasados, para el caso de los prestamos con planes de pago , recordad que si son varias cuotas vencidas, , debes sumarlas todas.

**LISTO**







**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Pantalla A Cobrar"PESTAÑA A COBRAR**
1. En esta pestaña se deben mostrar solo aquellos prestamos que no esten vencidos.
2. en la pestaña **atrasados** se deben mostrar aquellos prestamos que ya estan con cuotas vencidas.

**LISTO**







**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**EN TODO EL PROYECTO**
1. Crear un archivo en la carpeta MisAnotaciones que se llame "ColorModeDart" ahi agrega todos los tipos de componentes que tentemos agrupados por tipo y su color correspondiente. esto solo para el modo oscuro que actualmente esta implementado.

**listo**






















**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

Actualmente en el modo oscuro tenemos colores que no son los correctos, por eso necesito que implementemos(sustituye los actuales) por los siguientes colores, solo para el modo oscuro que esta en Ajustes > Apariencia > Modo de tema:

**“Nocturne Emerald”**

Enfocada en verde/teal moderno (dinero/acción) + azul profundo para UI.

**Tokens base**
Token	Hex
Background (Scaffold)	#0B0F14
Surface (Cards/AppBar/BottomBar)	#121826
Surface Elevated (cards “raised”)	#182235
Surface Variant (Inputs/Chips)	#1F2A44
Outline / Border	#2C3A5A
Divider	#22304A
**Colores vivos (acción/estados)**
Token	Hex
Primary (acciones principales)	#2D7DFF
OnPrimary (texto)	#FFFFFF
Secondary / Accent (dinero / confirmar)	#18D6B4
OnSecondary	#062019
Tertiary (detalle/links)	#B16CFF
Error	#FF4D6D
Warning	#FFB020
Info	#38BDF8
Success	#22C55E
**Textos e íconos**
Token	Hex
Text Primary	#EAF0FF
Text Secondary	#B7C3DE
Text Tertiary / Hint	#7F8FB3
Icon Inactive	#7F8FB3






**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

Actualmente en el modo oscuro  que esta en Ajustes > Apariencia > Modo de tema ; cuando se activa esa opcion hay campos que no se le esta aplicado la paleta de colores a como corresponde segun la paleta Nocturne Emerald, para asegurarnos de que todos los componentes visuales se vean correctamente en el modo oscuro, se realizo un inventario de todos los componentes visuales que se usan en la app, dichos componentes estan en el archivo ColorModeDart.md mas sin embargo he revisado el archivo ColorModeDart.md y he encontrado que hay componentes que no estan inventariados, por lo que tu tarea sera, ir cuidadosamente pantalla por pantalla en busca de componentes faltantes y agregarlos al archivo ColorModeDart.md ; asegurate de considerarlos todo, hay componentes que tienen inconos como por ejemplo el selector de moneda en la pantalla de prestamos , ese componente tiene un icono, ese tipo de componentes deben ser considerados y agregados al archivo ColorModeDart.md

**Listo**





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

Actualmente en el modo oscuro  que esta en Ajustes > Apariencia > Modo de tema ; cuando se activa esa opcion hay campos que no se le esta aplicado la paleta de colores a como corresponde segun la paleta Nocturne Emerald, para asegurarnos de que todos los componentes visuales se vean correctamente en el modo oscuro, se realizo un inventario de todos los componentes visuales que se usan en la app, dichos componentes estan en el archivo ColorModeDart.md asi que tu tarea sera, implementar la paleta de colores a todos los componentes visuales que se usan en la app, que esten inventariados en el archivo ColorModeDart.md

**Listo**



**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.


**PANTALLA ACERCA DE PRESTAZO**
1. El logo se ve todo cuadrado, debe mostrase redondo y bien estetico.


**PANTALLA DATOS DE LA EMPRESA**
1. los tuggles visible no tienen aplicado el modo oscuro.

**PANTALLA FRECUENCIA DE PAGO**
1. El boton nueva frecuencia no esta bien diseñado, se ve un circulo y el texto + Nueva frecuencia, hay que dejarlo bien estetico.

**PANTALLA gestion monetaria** 
1. en el campo , capital disponible el icono de guardar, aplicale un color mas claro de la paleta de colores Nocturne Emerald. ya que el que tiene no se logra apreciar.

**PANTALLA AJUSTES**
1. EN EL apartado consecutivos a los campos ultimo prestamo generado y ultimo recibo , reemplazar el icono de un check por un icono de un boton que indique guardar.
**listo** 










**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA A Cobrar**
1. en la pestaña AL Día, para el caso de los prestamos con planes de pago, el campo "Cuota" esta mostrando la suma de todas las cuotas del pestamo y no es asi. la logica es mostrar la cuota a pagar.




**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA A Cobrar**
1. en la pestaña AL Día, no se esta conciderando el campo "Planificar Cobro" que esta en ajustes, ese campo de dias de antelacion para mostrar los prestamos que se van a cobrar, debe ser respetado desde la pestaña Al Día en la pantalla A Cobrar. actualmente tengo un caso de un prestamo que su proxima cuota es el dia 19-02-26 y en dias de antelacion tengo configurado = 10 dias, por lo que el prestamo no se deberia de mostrar aún, mas sin embargo si se esta mostrando. revisa bien eso y corregilo.





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**PANTALLA Tasa de Cambio**
1. los campos: "Tasa Compra:" y "Tasa Venta:" no se aplican el modo oscuro. (me refiero al valor de esos campos, ejemplo Tasa Compra: 11.00, Tasa Venta: 11.00) los valores de esos campos no se aplican el modo oscuro. Actualmente tiene un color oscuro que no se logra apreciar.


**PANTALLA Agregar Tasa de Cambio**
1. Agergar un nuevo tuggle que diga:"Aplicar esta tasa a todo el mes"

**Logica a implementar**
1. Si el tuggle esta activado, la tasa de cambio se aplicara a todo el mes, y se deben de guardar esa misma tasa para cada dia del mes, inciando desde el dia 1 hasta el ultimo dia del mes actual. Esto se debe hacer cuando se presione el boton guardar, es decir al presionar el boton guardar si el tuggle esta activado, se debe de guardar la tasa de cambio para cada dia del mes actual, caso contrario mantener la logica actual de guardar la tasa de cambio solo para la fecha seleccionada por el usuario.

**Nota**
1.  todo este nuevo cambio, debes asegurarte de dejalor bien configurado para que se le aplique el modo oscuro a los campos y para que sea multi idioma.




**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Pantalla Al Día** esa pantalla se debe llamar "A Cobrar" , solo la pestaña "Al Día" es la que debe conservar ese nombre. Haz el cambio y asegurate de que ese nuevo nombre se refleje en todos los lugares donde se usa esa pantalla, incluyendo los archivos de idioma, incluso en los flujos de las pantalla para que todo el flujo siga funcionando correctamente.
**listo**













**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**Pantalla INICIO** 
1. haz una copia de la pantalla inicio(respaldo por si toca hacer rollback) y la original modificala para que obtengamos un nuevo diselo premuin siguiendo las siguientes instrucciones:




1) Alcance

Implementar únicamente la barra inferior de navegación (tabs: Inicio, etc.).

No modificar contenido de pantallas ni layouts superiores.

Mantener la lógica actual de navegación (índice seleccionado, cambio de tab, stack/pageview/navigator) intacta.

2) Reemplazo del componente actual

Sustituir el componente de barra inferior existente (Material BottomNavigationBar / NavigationBar / CupertinoTabBar / paquete equivalente) por un componente custom que:

Reciba selectedIndex

Reciba items (icon + label)

Exponga onSelect(index)

La lógica de cambio de tab debe seguir siendo la misma: solo cambia el render de la barra.

3) Colores: estrictamente Nocturne Emerald (sin hex nuevos)

Usar únicamente tokens/colores ya definidos en el tema (Nocturne Emerald). Prohibido hardcodear colores nuevos en el widget.

Asignación obligatoria por rol:

Background / scaffoldBackgroundColor = #0B0F14 → color del cutout.

Surface = #121826 → fondo de la barra.

Outline = #2C3A5A → borde sutil.

Primary = #2D7DFF → icono + label activo.

Accent/Secondary = #18D6B4 → solo para onda secundaria (pulse), con baja opacidad.

TextTertiary = #7F8FB3 → iconos inactivos (80–85% opacidad).

4) Geometría y estilo (valores exactos)

Barra (contenedor principal):

Altura: 76dp

Margen lateral: 16dp

Margen inferior: 12dp

Radio: 24dp (capsule/pill)

Fondo: Surface

Borde: 1dp con Outline (≈45% opacidad)

Sombra: suave (profundidad en dark sin “mancha”)

Ítems:

Máximo 5

Ícono: 24dp (activo alcanza 26dp en animación)

Label: solo el ítem activo muestra label (11–12sp, peso fuerte). Inactivos sin label.

5) Cutout premium (obligatorio)

Agregar un cutout circular centrado sobre el ítem activo:

Diámetro: 58dp

Debe “morder” la barra (superpuesto hacia arriba) para que el ítem activo se sienta encastrado.

El área del cutout debe mostrar el background real de la pantalla:

Usar scaffoldBackgroundColor/token Background (no un color aproximado).

Render del ícono activo dentro del cutout, centrado.

6) Animaciones (secuencia obligatoria)

Parámetros globales:

Duración base: 320ms

Curva: easeOutCubic

Al seleccionar un ítem:

Deslizamiento del cutout hacia el nuevo ítem (0–320ms).

Lift del ícono activo: elevar 3dp (sutil).

Micro-bounce controlado del ícono activo:

Escala: 1.00 → 1.12 → 1.00

Debe verse fino, no infantil.

7) Ondas (pulse premium, no ripple estándar)

Al seleccionar un ítem, disparar “pulse radial doble” desde el centro del ícono activo:

Onda 1 (Primary):

Color: Primary

Opacidad inicial: 14%

Radio: 0 → 52dp

Duración: 420ms

Fade a 0%

Onda 2 (Accent):

Color: Accent/Secondary

Opacidad inicial: 9%

Delay: 90ms después de la onda 1

Radio: 0 → 64dp

Duración: 420ms

Fade a 0%

Reglas:

No usar InkWell ripple default.

Ondas suaves (expand + fade) sin bordes duros.

Performance: mantener 60fps; si hay stutter, reducir costo visual antes de aceptar.

8) Estados de color

Ícono activo + label activo: Primary

Íconos inactivos: TextTertiary con opacidad 80–85%

Accent solo para onda secundaria, no para ícono activo permanente.

9) Criterios de aceptación (QA)

Cutout se integra perfecto con el fondo (se ve como hueco real, no parche).

Barra flotante premium (margen + sombra suave).

Selección: movimiento suave + lift + micro-bounce + doble onda.

Íconos inactivos visibles en dark mode.

Animaciones fluidas (60fps).





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**MEJORA*** 
1. Haz que cuando se habra nuestra app, se anule esa franja negra que es propia de android que aparece en la parte de abajo en color oscuro con las botones de navegacion atras y adelante y cerrar todo al medio.

**LISTO**








**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**MEJORA**
1. Despues del la mejroa que agregastes en Edge-to-Edge,  en las pantallas como incio , ajustes u otras pantallas cuando haces scroll hacia arriba , la parte de abajo no sube se queda detras del navbar , fijate en la imagen para que sepas a que me refiero.






**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**fix**
1. el problema persiste con el tema  Edge-to-Edge  ahora esta pasando con las pantallas internas como gestion monetarias, convecion financiera etc y adicional a eso cuando se activa el teclado cuando se escribe en cualquier formulario se sube una parte negra hasta arriba, podes verlo en la imagen. has el fix y no me actualices el code-rules.md hasta que yo te lo pida.
**LISTO**





**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**MEJORA EN PANTALLA DE CLIENTES**
1. En esta pantalla hay 2 limites arriba y abajo el limite de arriba es justo donde dice la cantidad de clientes y abajo es el navbar donde estan los botones de inicio, a cobrar, clientes...

**QUE HARAS**
1. Vas a crear un efecto premiun para ambos limites y haras que la tarjeta que este serca del limite ya sea arriba o abajo se desbanezca conforme se vaya asercando al limite hasta llegar a desaparece cuando este por debajo del limite.

2. otro efecto que haga que el color de la tarjeta que se aproxima a los limites ilumine por debajo de los limites pereciendo un efecto glasmorphism. este tambien debe ser un efecto premiun.

3. al boton de nuevo cliente redondo que esta actualmente , resaltalo un poco mas , que parezca que esta flotando , pero no muy exagerado.

**NOTA** 
al finalizar no reconstruyas el apk. eso lo hare yo.

**LISTO**










**nuevas mejroas**

Tómate un tiempo para analizar la siguiente mejora y haz el desarrollo considerando las reglas descritas en el archivo code-rules.md y apóyate del MCP de Dart para resolver los errores que aparezcan, así como para investigar sobre las buenas prácticas a la hora de escribir código.

**MEJORA EN PANTALLA DE CLIENTES**
1. YA PROBE la mejora y esta bueno, pero aun no es premium, es desvanecimiento debe ser mas delicado, mas sutil, mas premium, actualmente se que lo que hicistes es poner como una especia de transparencia en ambos limites.

**NOTA** 
al finalizar no reconstruyas el apk. eso lo hare yo.






