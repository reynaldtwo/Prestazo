

**1 Frecuencia Semanal**
**Escenario de prueba, para un prestamo, con un plan de pago "Bienvenida"**

**Datos del cliente**
Nombre=Juan Perez
Categoria=Bienvenida


**Convención Financiera**
convencion de conteo de días=30/360(estándar comercial)
dias por mes=30
dias por año=360
Reglas del prestamo=Días exactos
Politicas de redondeo:
decimales=4
Modo=Hacia arriba


**Datos de Plan de pago**
Nombre del plan=Bienvenida
Plazo=3
unidad de plazo=meses
frecuencia=Semanala(7 días)
total de cuotas=13
moneda=NIO
tasa=13.33% mensual
distribuir capital + interés en cuotas niveladas: SI
el periodo inicia en el desembolso=NO

**Datos del prestamo**
1. plan seleccionado=Bienvenida
2. capital=10,000.00
3. fecha desembolso=01-10-2025
4. fecha actual de prueba=15-01-2026


**Puntos a válidar**
1. Numero de cuotas creados
2. Monto en el campo "Esperado" y "Pendiente"
3. Ver si las fechas en los clicos creados son correctos.
4. capital + intereses


**Resultados de la prueba por QA**
El equipo de QA hiso ese mismo escenario con el plan "Bienvenida" y los resultados fueron desastrosos:
Resultado:
1. Numero de cuotas creados = (13, correcto)
2. Monto en el campo "Esperado" y "Pendiente" = (en ambos da 1,080.26 y la ultima 1,086.31)
3. Ver si las fechas en los clicos creados son correctos.=(correctos)
4. capital + intereses (da 14,043.43) = (incorrecto)

se solicita que revises bien todo el flujo para que el core realmente funcione al 100% y que realmente se apegue a las reglas de negocios configuradas en Ajustes.

El core (sistema) no debe tener nada harcodeado.












**2 Frecuencia Quincenal**
**Escenario de prueba, para un prestamo, con un plan de pago "Bienvenida"**

**Datos del cliente**
Nombre=Juan Perez
Categoria=Bienvenida


**Convención Financiera**
convencion de conteo de días=30/360(estándar comercial)
dias por mes=30
dias por año=360
Reglas del prestamo=Días exactos
Politicas de redondeo:
decimales=4
Modo=Hacia arriba


**Datos de Plan de pago**
Nombre del plan=Bienvenida
Plazo=3
unidad de plazo=meses
frecuencia=Quincenal
total de cuotas=6
moneda=NIO
tasa=13.33% mensual
distribuir capital + interés en cuotas niveladas: SI
el periodo inicia en el desembolso=NO

**Datos del prestamo**
1. plan seleccionado=Bienvenida
2. capital=10,000.00
3. fecha desembolso=01-11-2025



**Puntos a válidar**
1. Numero de cuotas creados
2. Monto en el campo "Esperado" y "Pendiente"
3. Ver si las fechas en los clicos creados son correctos.
4. capital + intereses