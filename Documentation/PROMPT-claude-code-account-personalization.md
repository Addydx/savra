# Prompt para Claude Code — Personalización de cuenta

Pégalo en Claude Code dentro del repo (`cd` a la raíz de `savra`). 5 fases, hazlas una por una con build/test entre cada una.

---

## Contexto para Claude Code

Estás en **Savra** (iOS, SwiftUI + SwiftData, Swift 5, iOS 17+), Clean Architecture por capas en `Savra/Savra/`: `Domain`, `Data`, `Infrastructure`, `Features` (MVVM), `Core/DI`.

Estado actual del apartado de cuenta — léelo antes de tocar nada:
- `Features/Profile/Views/ProfileView.swift`: solo muestra nombre/email fijos (de `AppViewModel.userDisplayName`/`userEmail`), un "Estado: Verificado" hardcodeado, versión hardcodeada, y "Cerrar sesión". No hay nada editable. No existe `ProfileViewModel`.
- `Domain/Models/User.swift`: existe pero no está conectado a ningún repositorio ni persistencia.
- `Infrastructure/Authentication/AuthServiceProtocol.swift` + `FirebaseAuthService.swift` + `SimulatorAuthService.swift`: solo tienen `signUp`, `signIn`, `signOut`, `sendEmailVerification`, `reloadUser`, `resetPassword`. No hay `updateDisplayName`, `updateEmail`, `updatePassword`, ni `deleteAccount`.
- No hay `UserProfileRepository` ni tabla SwiftData para perfil/preferencias — revisa `Data/Local/SwiftDataModels.swift` (modelos `SD*`, patrón `toDomain()`/`fromDomain()`) y `Data/Local/PersistenceService.swift` (registro del `Schema([...])`) para seguir el mismo patrón.
- `Infrastructure/Images/LocalImageService.swift` ya maneja fotos de comida (`prepareImageData(_:mealLogId:)`, guarda full + thumbnail en `Application Support/Images/`), pero está tipado específicamente a `MealLogId`. Para foto de perfil hay que generalizarlo.
- `Core/DI/AppContainer.swift`: aquí se inyectan todos los repos/servicios — sigue el mismo patrón para lo nuevo.
- `Documentation/IMPLEMENTATION_STATUS.md`, sección "Pending Decisions": la eliminación de cuenta está marcada como decisión diferida — la Fase E de este prompt la resuelve.

Después de cada fase corre:
```
xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test
```

---

## FASE A — Base: `ProfileViewModel` + persistencia de perfil

1. Crea `Features/Profile/ViewModels/ProfileViewModel.swift` (`@MainActor @Observable`, mismo patrón que `DashboardViewModel`). `ProfileView` hoy usa `AppViewModel` directo; muévele la lógica de edición a este nuevo ViewModel, dejando `AppViewModel` solo para sesión/auth global.
2. Añade `SDUserProfile` en `SwiftDataModels.swift`: `id`, `userId`, `displayName`, `photoLocalPath: String?`, `photoThumbnailPath: String?`, `createdAt`, `updatedAt`, con su `toDomain()`/`fromDomain()`. Regístralo en el `Schema([...])` de `PersistenceService.swift`.
3. Crea `Domain/RepositoryProtocols/UserProfileRepository.swift` (`fetch(userId:)`, `upsert(_:)`) + `Data/RepositoryImplementations/SwiftDataUserProfileRepository.swift`, siguiendo el patrón de `SwiftDataMealPlanRepository.swift`.
4. Generaliza `ImageServiceProtocol.prepareImageData` para aceptar un identificador genérico (`UUID`) en vez de `MealLog.ID` específicamente, o añade un método hermano `prepareProfileImageData(_:userId:)` que reutilice la misma lógica de compresión/thumbnail.
5. Inyecta el nuevo repo en `AppContainer`.

**Criterio de aceptación**: existe una fuente de verdad local para nombre/foto de perfil, independiente de Firebase Auth, con su propio ViewModel.

---

## FASE B — Editar nombre y foto

1. `AuthServiceProtocol`: añade `func updateDisplayName(_ name: String) async throws`. Implementa en `FirebaseAuthService` (usa `createProfileChangeRequest()` igual que en `signUp`) y en `SimulatorAuthService` (actualiza el estado simulado en memoria).
2. `ProfileViewModel`: `updateProfile(name:photoData:)` que llama `authService.updateDisplayName(_:)`, guarda la foto con el servicio de imágenes de la Fase A, hace upsert en `UserProfileRepository`, y actualiza `AppViewModel.userDisplayName` para que se refleje en Dashboard/toolbar sin reiniciar la app.
3. UI: pantalla `Features/Profile/Views/EditProfileView.swift` — avatar circular tappable (usa `PhotosPicker`, mismo patrón que `addPhotoView` en `MealLoggingFlowView`) + `TextField` de nombre. Ábrela desde un botón "Editar" en `ProfileView`.
4. Si no hay foto de perfil, muestra iniciales del nombre sobre un círculo de color (fallback, sin depender de assets).

**Criterio de aceptación**: cambiar nombre y/o foto persiste entre reinicios de la app y se refleja de inmediato en Dashboard y Perfil.

---

## FASE C — Seguridad: cambiar contraseña y correo

Firebase exige reautenticación reciente para `updateEmail`/`updatePassword` (lanza `requiresRecentLogin` si no). Diseña el flujo asumiendo esto:

1. `AuthServiceProtocol`: añade `func reauthenticate(password: String) async throws`, `func updateEmail(_ newEmail: String) async throws`, `func updatePassword(_ newPassword: String) async throws`. Implementa los tres en `FirebaseAuthService` (usa `EmailAuthProvider.credential` + `reauthenticate(with:)`, luego `currentUser?.updateEmail`/`updatePassword`) y stubs coherentes en `SimulatorAuthService`.
2. Añade los casos de error que falten a `AuthError` (ej. `.requiresRecentLogin`) con mensaje claro en español, mapeados desde `AuthErrorCode` en `AuthError.from(_:)`.
3. UI: sección "Seguridad" en `ProfileView` con dos flujos, cada uno pidiendo la contraseña actual antes de aplicar el cambio (reautenticación inline, no una pantalla aparte):
   - Cambiar contraseña: contraseña actual + nueva + confirmar nueva (mínimo 6 caracteres, mismo criterio que `AuthError.weakPassword`).
   - Cambiar correo: correo nuevo + contraseña actual. Tras el cambio, dispara `sendEmailVerification()` de nuevo (ya existe) porque Firebase marca el nuevo correo como no verificado.
4. Feedback de éxito/error visible inline, reusando el patrón de `errorMessage` que ya usan `MealLoggingViewModel`/las vistas de `Features/Authentication`.

**Criterio de aceptación**: un usuario puede cambiar su contraseña o correo sin cerrar sesión manualmente, con reautenticación transparente y mensajes de error claros si la contraseña actual es incorrecta.

---

## FASE D — Preferencias de la app

1. `Domain/Models/AppPreferences.swift`: `theme: Theme` (`system/light/dark`), `preferredUnit: String` (ej. "g" vs "oz", coherente con el picker de unidad que ya existe en el registro de comidas de la Fase 1 del prompt anterior), `defaultNotificationsEnabled: Bool`.
2. Persistencia simple vía `UserDefaults` (no necesita SwiftData ni sync): protocolo `PreferencesStore` en `Domain` o `Core`, implementación `UserDefaultsPreferencesStore` en `Infrastructure`, inyectada en `AppContainer`.
3. UI: sección "Preferencias" en `ProfileView` — `Picker` de tema (aplica con `.preferredColorScheme` en `AppRootView` o el `App` root), `Picker` de unidad por defecto (se usa como valor inicial en el stepper de cantidad/unidad del registro de comidas), `Toggle` de notificaciones por defecto para planes nuevos (se usa como valor inicial de `notificationsEnabled` en `MealPlanFormView`).

**Criterio de aceptación**: cambiar el tema se aplica sin reiniciar la app; crear un plan o registrar una comida nueva usa las preferencias guardadas como default (pero siguen siendo editables por instancia).

---

## FASE E — Eliminar cuenta

Antes de programar, escribe `Documentation/ADR-009-account-deletion.md` (mismo formato que los ADR existentes) documentando la decisión: qué se borra, en qué orden, y cómo se maneja `requiresRecentLogin`. Luego implementa:

1. `AuthServiceProtocol`: `func deleteAccount() async throws` — en `FirebaseAuthService` requiere reautenticación (mismo mecanismo de la Fase C) antes de `currentUser?.delete()`.
2. Antes de borrar la cuenta en Firebase, limpia todo lo local del `userId` actual: `MealPlan`, `MealOccurrence`, `MealLog`/`MealLogItem`/fotos en disco (usa `ImageServiceProtocol.deleteImage`), logros desbloqueados, y el `UserProfile` de la Fase A (incluida su foto). Hazlo en una función tipo `DeleteAccountUseCase` en `Domain/UseCases` que orqueste los repos, no en la vista.
3. UI: en `ProfileView`, sección separada (destructiva, al fondo) "Eliminar cuenta" → pantalla de confirmación con explicación clara de que es irreversible, pide contraseña actual, y requiere escribir "ELIMINAR" (o similar) antes de habilitar el botón.
4. Tras eliminar con éxito, cierra sesión y regresa al flujo de `Features/Authentication`.

**Criterio de aceptación**: eliminar la cuenta borra todos los datos locales del usuario, borra la cuenta en Firebase Auth, y deja la app en el estado de "no autenticado" sin rastros de datos del usuario eliminado.

---

## Al terminar cada fase

- Corre build + tests.
- Actualiza `Documentation/IMPLEMENTATION_STATUS.md`.
- Fase E requiere el ADR nuevo antes de codear, no después.
