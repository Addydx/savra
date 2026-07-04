# ADR-007 — Recurrence Model

## Context

Los planes de comida necesitan repetirse (una vez, diario, días específicos) sin construir un motor de recurrencia completo tipo RFC 5545 (iCalendar RRULE).

## Decision

Value object `RecurrenceRule` simplificado (`kind: once | daily | specificDays`, `daysOfWeek`, `startDate`, `endDate?`) con generación de `MealOccurrence` por ventana móvil de 30 días, regenerada al abrir la app o editar un plan.

## Alternatives Considered

* **RRULE completo (iCalendar)**: descartado; soporta casos (ej. "cada dos semanas", "el tercer martes del mes") que no están en el alcance del MVP y añadirían complejidad de parsing/cálculo innecesaria.
* **Generar todas las ocurrencias futuras de una vez hasta una fecha muy lejana**: descartado; desperdicia almacenamiento y complica la edición de reglas activas (habría que borrar/regenerar masivamente).
* **Calcular ocurrencias 100% al vuelo sin persistirlas nunca**: descartado; se necesita persistir `MealOccurrence` porque cada una tiene su propio estado (`completed`, `skipped`, etc.) que es un hecho histórico, no derivable solo de la regla.

## Consequences

* La ventana móvil requiere que `GenerateOccurrencesUseCase` se ejecute regularmente (al abrir la app, al crear/editar un plan) — es un costo aceptado y simple.

## Risks

* Si el usuario no abre la app por más de 30 días, al reabrirla la ventana se regenera correctamente desde "hoy", sin huecos — riesgo mitigado por diseño.

## Status

Proposed
