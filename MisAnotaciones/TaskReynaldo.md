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