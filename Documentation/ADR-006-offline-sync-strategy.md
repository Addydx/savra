# ADR-006 — Offline and Synchronization Strategy

## Context

La app debe funcionar completamente offline para sus funciones principales, y sincronizar cambios de forma confiable cuando regrese la conexión, con un solo usuario (probablemente en un único dispositivo activo la mayoría del tiempo).

## Decision

Cola de sincronización local persistida (`SyncQueueEntry`) procesada por un `SyncEngine` (actor), con resolución de conflictos **last-write-wins basada en `updatedAt`**, con excepción explícita para `MealLog`/`MealPhoto` (nunca se descartan silenciosamente datos de contenido divergente).

## Alternatives Considered

* **CRDTs / vector clocks**: descartado; resuelve un problema de concurrencia multi-dispositivo simultánea que este producto no tiene en su etapa actual (sobreingeniería).
* **Sincronización síncrona bloqueante (esperar respuesta del servidor antes de continuar)**: descartado; viola offline-first.
* **Depender únicamente de la persistencia offline nativa de Firestore sin cola propia**: parcialmente viable, pero se prefiere una cola explícita propia para tener control y visibilidad sobre estados de error/reintento (ver 09-OFFLINE-AND-SYNC.md), en vez de depender enteramente de comportamiento interno opaco del SDK.

## Consequences

* Se añade una entidad de infraestructura (`SyncQueueEntry`) que no es parte del dominio, pero da observabilidad sobre el estado de sincronización.

## Risks

* La política last-write-wins puede, en casos raros de edición concurrente real en dos dispositivos, descartar una edición legítima; se documenta como riesgo aceptado para el MVP y revisable si se detectan casos reales en producción.

## Status

Proposed
