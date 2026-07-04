# ADR-005 — Image Storage

## Context

Las fotos de comida deben poder capturarse offline, mostrarse rápidamente en listas (miniaturas) y sincronizarse cuando haya red, sin acoplar el registro de comida a un proveedor concreto de forma irreversible.

## Decision

Almacenamiento local (sandbox de la app) como fuente inmediata + Firebase Storage como destino remoto, con `MealPhoto` como entidad propia con su propio `syncStatus` independiente del `MealLog`.

## Alternatives Considered

* **Guardar la foto como blob directamente en la base de datos (SwiftData/Firestore)**: descartado; ineficiente para archivos binarios grandes y dificulta el streaming/caché de miniaturas.
* **Subir la foto de forma síncrona antes de permitir guardar el `MealLog`**: descartado; violaría el principio offline-first (el registro debe poder guardarse localmente de inmediato aunque la foto tarde en subir).
* **CDN de terceros independiente de Firebase (ej. Cloudinary)**: viable a futuro para optimización de imágenes, pero sobredimensionado para el MVP dado que ya se usa Firebase para Auth/DB.

## Consequences

* `MealPhoto` puede quedar en `pendingUpload` mientras el resto del `MealLog` ya está `synced`, lo cual es correcto y esperado.

## Risks

* Fotos grandes sin comprimir podrían consumir espacio de disco local significativo si el usuario registra muchas comidas con foto — mitigado por la estrategia de compresión definida en 10-IMAGE-ARCHITECTURE.md.

## Status

Proposed
