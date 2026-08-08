# ADR-009 — Account Deletion

## Context

Savra necesita permitir a un usuario eliminar su cuenta y todos sus datos personales (planes, ocurrencias, registros de comida, fotos, logros, perfil) tanto localmente (SwiftData + `Application Support/Images/`) como en Firebase Auth, sin dejar rastros ni estados inconsistentes si el proceso falla a medio camino. Firebase exige reautenticación reciente (`requiresRecentLogin`) antes de operaciones sensibles como `updateEmail`, `updatePassword` y `delete()` de la cuenta (ver ADR-002 y la Fase C del prompt de personalización de cuenta).

## Decision

1. **Reautenticación primero, sin excepciones**: `DeleteAccountUseCase.execute(userId:currentPassword:)` llama `authService.reauthenticate(password:)` como primer paso. Si falla (contraseña incorrecta o `requiresRecentLogin` persiste), no se toca ningún dato local ni remoto.
2. **Orden de borrado: local primero, luego Firebase Auth.** Tras una reautenticación exitosa:
   a. Fotos de `MealLog` en disco (vía `ImageServiceProtocol.deleteImage`), luego las filas de `MealLog` (SwiftData `.cascade` limpia `MealLogItem`/`SDMealLogPhoto` automáticamente).
   b. `MealOccurrence`.
   c. `MealPlan`.
   d. `UnlockedAchievement`.
   e. Foto de perfil en disco, luego la fila de `UserProfile`.
   f. Finalmente, `authService.deleteAccount()` (borra el usuario en Firebase Auth, aprovechando la reautenticación reciente del paso 1).
3. Toda la orquestación vive en `Domain/UseCases/DeleteAccountUseCase.swift`, dependiendo solo de protocolos (`MealPlanRepository`, `MealOccurrenceRepository`, `MealLogRepository`, `AchievementRepository`, `UserProfileRepository`, `ImageServiceProtocol`, `AuthServiceProtocol`), no de la vista ni de tipos concretos de Infraestructura — mismo patrón que `EvaluateAchievementsUseCase`.
4. Cada repositorio gana un método de borrado masivo por `userId` (`deleteAll(for:)`, o `delete(userId:)` en `UserProfileRepository` por ser de cardinalidad 0/1) en vez de que el `UseCase` haga fetch + loop de deletes individuales — un solo `context.save()` por repo, y la lógica de borrado masivo queda encapsulada junto al resto de la lógica SwiftData de cada entidad.
5. **Manejo de `requiresRecentLogin`**: como el borrado local ocurre inmediatamente después de una reautenticación exitosa (mismo `Task`, sin esperas de usuario de por medio), la sesión permanece "reciente" para Firebase cuando se llama `deleteAccount()` al final. No se requiere una segunda reautenticación explícita antes de `currentUser?.delete()`.

## Alternatives Considered

* **Borrar la cuenta en Firebase primero, luego los datos locales**: descartado. Si el borrado local fallara después (p. ej. error de disco), la cuenta de Firebase ya no existiría pero quedarían datos huérfanos del usuario en el dispositivo sin ninguna sesión válida para volver a intentar limpiarlos — viola el criterio de "sin rastros de datos del usuario eliminado".
* **Reautenticar dos veces (antes del borrado local y de nuevo justo antes de `deleteAccount()`)**: descartado por redundante; Firebase considera "reciente" un login de los últimos minutos, y ambos pasos ocurren en la misma operación sin intervención del usuario entre medio.
* **Orquestar el borrado desde `ProfileView` llamando a los repos directamente**: descartado; rompe la separación de capas y sería imposible de testear sin UI. Se centraliza en un `UseCase` de `Domain`.
* **Soft delete (marcar la cuenta como eliminada pero conservar los datos un tiempo por si el usuario se arrepiente)**: descartado para el MVP; añade complejidad de "cuentas zombie" y un job de limpieza diferido que no está justificado todavía. Puede reconsiderarse si el producto lo requiere más adelante.

## Consequences

* Si `deleteAccount()` falla tras el borrado local (p. ej. sin red), el usuario pierde sus datos locales pero su cuenta de Firebase sigue existiendo — puede reintentar iniciando sesión y volviendo a pedir la eliminación (el borrado local ya no tendrá nada que hacer, y solo restará reintentar el paso de Firebase). Se documenta como comportamiento esperado, no como bug.
* Los repositorios ganan una responsabilidad más (`deleteAll`/`delete(userId:)`), pero mantiene el patrón Repository ya establecido en el resto del proyecto.

## Risks

* Si el usuario cierra la app a mitad del proceso de borrado, podría quedar en un estado parcial (algunos datos locales borrados, cuenta de Firebase aún viva). Mitigado porque cada paso es idempotente: reintentar la eliminación de cuenta simplemente no encontrará nada que borrar en los repos ya vacíos y completará el paso de Firebase restante.
* `EmailAuthProvider`/`reauthenticate` requiere que el usuario tenga contraseña (no aplica a proveedores OAuth); dado que Savra solo soporta email/password (ADR-002), no es un problema actual pero limitaría esta función si se añadiera Sign in with Apple/Google sin actualizar este flujo.

## Status

Proposed
