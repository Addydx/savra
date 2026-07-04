# ADR-008 — Food Catalog Source

## Context

El usuario necesita poder buscar y añadir alimentos/ingredientes a un registro, sin acoplar la app a una API externa concreta desde el inicio.

## Decision

Abstracción `FoodCatalogRepository` con dos implementaciones activas en el MVP: `LocalFoodCatalog` (catálogo estático embebido con alimentos comunes) y `UserCreatedFoodCatalog` (alimentos que el propio usuario crea cuando no encuentra lo que busca). `RemoteFoodCatalog` se define como interfaz pero **no se implementa en el MVP**.

## Alternatives Considered

* **Solo API externa (ej. Open Food Facts, USDA)** desde el MVP: descartado; añade dependencia de red y de disponibilidad de un tercero para la función más usada de la app (registrar comida), lo cual choca con el requisito offline-first. Se deja como implementación futura de `RemoteFoodCatalog`, combinable con la local (catálogo local como fallback offline, remoto como fuente ampliada cuando hay red).
* **Solo catálogo creado por el usuario (sin catálogo local predefinido)**: descartado; obligaría al usuario a crear manualmente hasta los alimentos más comunes (huevo, arroz, café) desde el primer uso, generando fricción innecesaria en la función principal del producto.
* **Base de datos nutricional completa desde el inicio**: descartado explícitamente; el MVP no hace conteo de calorías/macros, por lo que un catálogo nutricional completo sería sobreingeniería (ver 01-MVP-SCOPE.md).

## Consequences

* `FoodCatalogRepository` combina resultados de `LocalFoodCatalog` + `UserCreatedFoodCatalog` (filtrado por el usuario actual) en las búsquedas del MVP.
* Añadir `RemoteFoodCatalog` en el futuro no requiere cambios en `Features/MealLogging`, solo una nueva implementación del mismo protocolo y una estrategia de combinación/priorización de resultados.

## Risks

* El catálogo local inicial necesitará mantenimiento manual de una lista razonable de alimentos comunes; se recomienda empezar con un set curado pequeño (decenas, no miles) y dejar que `UserCreatedFoodCatalog` cubra el resto orgánicamente.

## Status

Proposed
