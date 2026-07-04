# ADR-004 — Remote Backend

## Context

Se necesita un backend remoto para sincronizar datos entre dispositivos y como respaldo, sin construirlo desde cero.

## Decision

Firestore (junto con Firebase Auth y Firebase Storage, ver ADR-002) como backend remoto para el MVP.

## Alternatives Considered

Ver tabla comparativa completa en 07-AUTHENTICATION-ARCHITECTURE.md (Firebase vs Supabase vs AWS Amplify vs backend propio). Firestore se prioriza sobre Supabase/Postgres principalmente por su **soporte offline nativo con sincronización automática**, que reduce significativamente el trabajo de construir una cola de sincronización completamente manual.

## Consequences

* El dominio y las Features nunca acceden a Firestore directamente; solo lo hacen las implementaciones concretas en `Data/RepositoryImplementations` y `Data/Remote`.
* Las queries de historial (rango de fechas) requieren índices compuestos explícitos en Firestore.

## Risks

* Si en el futuro se necesitan reportes/analítica compleja (Post-MVP: estadísticas de constancia), un modelo relacional (Postgres/Supabase) sería más natural — riesgo documentado, no bloqueante ahora.
* Costes de Firestore escalan con número de lecturas/escrituras, no solo almacenamiento; requiere diseño cuidadoso de queries para evitar lecturas innecesarias (ej. no releer todo el historial en cada apertura, ver FR-HISTORY-002).

## Status

Proposed
