# ADR-003 — Local Persistence

## Context

La app debe funcionar offline-first: crear/editar/registrar datos sin conexión y sincronizar después.

## Decision

SwiftData como motor de persistencia local (fuente de verdad inmediata).

## Alternatives Considered

* **Core Data directo**: SwiftData es la evolución moderna de Core Data con mejor ergonomía en Swift/SwiftUI (macros, integración con `@Query`); se prefiere para un proyecto nuevo, salvo que se necesite compatibilidad con iOS muy antiguo (no es el caso aquí).
* **Realm**: descartado; añade una dependencia externa pesada cuando SwiftData ya cubre las necesidades del MVP y tiene mejor integración nativa futura con el ecosistema Apple.
* **SQLite directo / GRDB**: descartado para el MVP por mayor trabajo manual de mapeo objeto-relacional; SwiftData ya resuelve esto de forma declarativa.
* **Solo Firestore local cache (sin SwiftData)**: descartado porque acoplaría el modelo de dominio directamente al SDK de Firestore, dificultando testear el dominio de forma aislada y complicando un eventual cambio de backend.

## Consequences

* Modelos de `Data/Local` se mapean explícitamente desde/hacia `Domain/Models`, evitando que SwiftData "se filtre" al dominio.

## Risks

* SwiftData es relativamente nuevo; posibles limitaciones o bugs de framework en casos avanzados de queries — mitigar validando pronto (Phase 0/1) las queries clave (historial paginado, filtrado por usuario).

## Status

Proposed
