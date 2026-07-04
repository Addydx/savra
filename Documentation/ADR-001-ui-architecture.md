# ADR-001 — UI Architecture

## Context

Se necesita una arquitectura de UI para una app nativa iOS, mantenible por un desarrollador (o equipo pequeño) que pueda crecer sin reescritura mayor.

## Decision

SwiftUI + Feature-based organization + MVVM, con Use Cases del dominio invocados desde los ViewModels solo cuando hay lógica de negocio no trivial (ver 06-APPLICATION-ARCHITECTURE.md).

## Alternatives Considered

* **UIKit + MVC**: descartado; mayor boilerplate, peor alineado con el ciclo de vida reactivo que necesita el Dashboard/calendario.
* **SwiftUI + TCA (The Composable Architecture)**: descartado para el MVP; añade una curva de aprendizaje y ceremonia (reducers, actions, stores) que no se justifica todavía con la complejidad actual del dominio. Reevaluar si el proyecto crece mucho en superficie de estado compartido.
* **SwiftUI + MV (sin ViewModels, estado directo en la View con `@State`/`@Observable` de los modelos)**: viable para pantallas muy simples, pero se descarta como enfoque único porque varias pantallas (registro de comida, planes) tienen suficiente lógica de orquestación como para beneficiarse de un ViewModel testeable de forma aislada.

## Consequences

* Cada Feature es independiente y testeable por separado.
* Se requiere disciplina para no dejar que los ViewModels acumulen lógica de negocio que debería vivir en Domain/UseCases.

## Risks

* Con un equipo de un solo desarrollador, existe el riesgo de mezclar responsabilidades bajo presión de tiempo; mitigar con revisión periódica de qué vive en ViewModel vs UseCase.

## Status

Proposed
