# Criterios de Aceptación (Gherkin) V1 – PrestamosApp

## Feature: Clientes
Scenario: Crear cliente quincenal
  Given la app está abierta
  When creo un cliente con nombre, frecuencia "BIWEEKLY"
  Then el cliente queda guardado y aparece en el listado de clientes

Scenario: Desactivar cliente
  Given existe un cliente activo
  When cambio el estado a "INACTIVE"
  Then el sistema bloquea la creación de nuevos préstamos para ese cliente

## Feature: Préstamos
Scenario: Crear préstamo genera primer ciclo
  Given existe un cliente con frecuencia "MONTHLY"
  When creo un préstamo con capital, tasa mensual y fecha de desembolso
  Then el sistema crea el préstamo en estado "ACTIVE"
  And crea al menos 1 BillingCycle con InterestExpected calculado

## Feature: Pagos
Scenario: Registrar pago solo interés aplica a ciclo vencido primero
  Given un préstamo tiene 2 ciclos vencidos con interés pendiente
  When registro un pago por monto igual al interés pendiente del ciclo más antiguo
  Then el pago se registra como VALID
  And se crea una allocation INTEREST al ciclo más antiguo
  And el interés pendiente de ese ciclo queda en 0

Scenario: Registrar pago mixto aplica interés y capital
  Given un préstamo tiene interés pendiente y saldo capital > 0
  When registro un pago mixto
  Then el sistema asigna primero a interés y luego a capital
  And actualiza PrincipalBalance correctamente

Scenario: No permitir excedente
  Given un préstamo tiene saldo total adeudado de 500
  When intento registrar un pago de 600
  Then el sistema rechaza el pago indicando "Monto excede lo adeudado"

## Feature: Mora
Scenario: Préstamo entra en mora tras días de tolerancia
  Given existe un ciclo vencido con interés pendiente
  And han pasado más de MoratoriumDays desde DueDate
  When consulto el estado del préstamo
  Then el préstamo está en estado "IN_MORA"

## Feature: Capitalización
Scenario: Capitalización ON suma interés pendiente al capital
  Given CapitalizeUnpaidInterest está activo
  And existe un ciclo vencido con interés pendiente
  When se ejecuta el job de capitalización
  Then PrincipalBalance aumenta en el monto del interés pendiente
  And el ciclo queda cerrado y marcado como capitalizado

## Feature: Anulación
Scenario: Anular pago recalcula saldos
  Given existe un pago VALID aplicado a interés y capital
  When anulo el pago con un motivo
  Then el pago queda VOIDED
  And el saldo del préstamo y ciclos se recalculan desde allocations válidas
