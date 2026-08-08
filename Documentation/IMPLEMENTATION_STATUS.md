# Implementation Status

## Current Phase

All 5 phases of `PROMPT-claude-code-account-personalization.md` are complete.

## Completed

- **Account Personalization — Phase E: delete account**:
  - Wrote `Documentation/ADR-009-account-deletion.md` first, documenting what gets deleted, in what order (local data — meal log photos/rows, occurrences, plans, achievements, profile+photo — before the Firebase Auth account), and why `requiresRecentLogin` is handled by reauthenticating once up front rather than a second time right before `deleteAccount()`.
  - Added `AuthServiceProtocol.deleteAccount()`, implemented in `FirebaseAuthService` (`currentUser?.delete()`) and `SimulatorAuthService` (clears its `UserDefaults` session keys). Same `#if !targetEnvironment(simulator)` caveat as Phase C's real-branch code applies.
  - Added `deleteAll(for userId:)` to `MealPlanRepository`, `MealOccurrenceRepository`, `MealLogRepository`, `AchievementRepository` (+ SwiftData implementations, each a predicate fetch + delete loop + single `context.save()`), and `delete(userId:)` to `UserProfileRepository`.
  - Added `ImageServiceProtocol.deleteImage(at:)` (was already implemented on `LocalImageService`, just not declared on the protocol) so `Domain` code can depend on the abstraction instead of the concrete type.
  - Added `Domain/UseCases/DeleteAccountUseCase.swift` (same protocol-only-dependency pattern as `EvaluateAchievementsUseCase`): reauthenticates, deletes meal-log photos from disk then the DB rows (SwiftData cascade handles `MealLogItem`/`SDMealLogPhoto`), then occurrences, plans, achievements, profile photo + row, and finally the Firebase Auth account. Injected into `AppContainer` as `deleteAccountUseCase`.
  - Added `ProfileViewModel.deleteAccount(currentPassword:) -> Bool` and `Features/Profile/Views/DeleteAccountView.swift`: irreversibility warning, current-password field, and a "type ELIMINAR to confirm" field gating the destructive button. Opened from a new destructive "Eliminar cuenta" section at the bottom of `ProfileView`, below "Cerrar sesión". On success, calls `AppViewModel.signOut()`, which flips `authState` to `.signedOut` and lets `AppRootView` swap to the `Features/Authentication` flow on its own — no manual navigation needed.
- **Account Personalization — Phase D: app preferences**:
  - Added `Domain/Models/AppPreferences.swift` (`theme: Theme` `system/light/dark`, `preferredUnit: String`, `defaultNotificationsEnabled: Bool`, plus a `.default`).
  - Added `Core/Preferences/PreferencesStore.swift` protocol (`load()`/`save(_:)`, synchronous — it's a thin `UserDefaults` wrapper, not a repository) and `Infrastructure/Preferences/UserDefaultsPreferencesStore.swift`, injected into `AppContainer`.
  - Added `Core/Preferences/ThemeSettings.swift`, a tiny `@Observable` holder for the *live* theme (separate from the `AppPreferences` snapshot) so changing it in Settings updates the UI without a restart. `AppContainer` seeds it from `preferencesStore.load().theme` at launch; `AppRootView` applies `.preferredColorScheme(container.themeSettings.theme.colorScheme)` reading through the observable chain, and `ProfileViewModel.updateTheme(_:)` writes to both the store (persisted) and `themeSettings` (live UI).
  - `ProfileViewModel` gained a `preferences: AppPreferences` snapshot loaded at init, plus `updateTheme`/`updatePreferredUnit`/`updateDefaultNotificationsEnabled`, each persisting immediately via `preferencesStore.save(_:)`.
  - Added `Features/Profile/Views/PreferencesSectionView.swift`: a "Preferencias" `Section` in `ProfileView` (theme `Picker`, unit `Picker` reusing `MealLoggingViewModel.unitOptions` for consistency with the meal-logging unit picker, notifications `Toggle`).
  - Wired the defaults through to where they're consumed per-instance: `MealLoggingViewModel`'s per-food `defaultUnit` now reads `preferencesStore.load().preferredUnit` at init (falling back to "porción" if the stored value isn't one of `unitOptions`) instead of a hardcoded constant. `MealPlanFormView` gained an actual `notificationsEnabled` `Toggle` (previously always hardcoded to `false` with no UI control at all) defaulting to `preferencesStore.load().defaultNotificationsEnabled` for new plans, `editPlan?.notificationsEnabled` when editing — both remain editable per-instance. `MealPlansViewModel.container` was made non-private so the form could reach the store.
- **Account Personalization — Phase C: change password and email**:
  - Added `AuthServiceProtocol.reauthenticate(password:)`, `.updateEmail(_:)`, `.updatePassword(_:)`. `FirebaseAuthService` implements them with `EmailAuthProvider.credential(withEmail:password:)` + `user.reauthenticate(with:)`, then `user.updateEmail(to:)`/`updatePassword(to:)`. **Caveat**: like the rest of `FirebaseAuthService`'s real branch, this code lives behind `#if !targetEnvironment(simulator)` and is never compiled by the simulator build/test commands this project standardizes on — only `SimulatorAuthService`'s stubs are exercised by `xcodebuild ... -destination 'platform=iOS Simulator...'`. A `generic/platform=iOS` build (done once during Phase 0 setup) would be needed to type-check the real Firebase branch.
  - `SimulatorAuthService` gets coherent stand-ins: `reauthenticate` just rejects an empty password (there's no real password to check), `updateEmail` writes the `UserDefaults` email key, `updatePassword` is a no-op.
  - Added `AuthError.requiresRecentLogin` (Spanish message) mapped from `AuthErrorCode.requiresRecentLogin` in `AuthError.from(_:)`.
  - Added `ProfileViewModel.changePassword(currentPassword:newPassword:)` and `.changeEmail(newEmail:currentPassword:)`, both reauthenticating first; `changeEmail` also re-triggers `sendEmailVerification()` (Firebase marks a changed email unverified) and updates `AppViewModel.userEmail` immediately. Added a `successMessage` alongside the existing `errorMessage` for inline feedback.
  - Added `Features/Profile/Views/SecuritySectionView.swift`: a "Seguridad" `Section` embedded directly in `ProfileView`'s `List` (no separate screen, per the prompt) with two `DisclosureGroup` inline forms — change password (current + new + confirm, ≥6 chars) and change email (new email + current password) — each collapsing back and clearing its fields on success.
- **Account Personalization — Phase B: edit name and photo**:
  - Added `AuthServiceProtocol.updateDisplayName(_:)`, implemented in `FirebaseAuthService` (via `createProfileChangeRequest()`, same as `signUp`) and `SimulatorAuthService` (writes to the same `UserDefaults` key `currentUserName` reads).
  - Added `ProfileViewModel.updateProfile(name:photoData:)`: calls `authService.updateDisplayName`, saves a new photo via `imageService.prepareProfileImageData` (Phase A) only when `photoData` is provided (keeps existing paths otherwise), upserts `UserProfileRepository`, and — since `ProfileViewModel` now takes an optional `appViewModel: AppViewModel` reference — writes straight to `AppViewModel.userDisplayName` so Dashboard/toolbar update without an app restart.
  - Added `Features/Profile/Views/ProfileAvatarView.swift`, a small reusable component (photo if present, else initials-on-accent-circle fallback) shared by `ProfileView`'s header and the new `Features/Profile/Views/EditProfileView.swift` (tappable `PhotosPicker` avatar with a camera badge + name `TextField`), opened from an "Editar" button in `ProfileView`.
  - Fixed a Swift concurrency warning introduced along the way: reading the `@MainActor`-isolated `viewModel.photoThumbnailPath` directly inside `PhotosPicker`'s label closure isn't isolated; hoisted it into a local `let` computed in `body` instead.
  - Verified manually in the iOS Simulator: edited the name in `EditProfileView`, saved, watched `ProfileView`'s header update immediately (no restart), then force-quit and relaunched the app — the new name persisted from `SDUserProfile`.
- **Account Personalization — Phase A: `ProfileViewModel` + profile persistence**:
  - Added `Domain/Models/UserProfile.swift` and `Domain/RepositoryProtocols/UserProfileRepository.swift` (`fetch(userId:)`, `upsert(_:)`).
  - Added `SDUserProfile` to `SwiftDataModels.swift` (`displayName`, `photoLocalPath`, `photoThumbnailPath`, timestamps) + `toDomain()`/`fromDomain()`, registered in `PersistenceService`'s `Schema([...])`.
  - Added `Data/RepositoryImplementations/SwiftDataUserProfileRepository.swift` following the `SwiftDataMealPlanRepository` pattern.
  - Generalized image handling without duplicating the compression/thumbnail logic: `LocalImageService` now has a private `prepareImage(_:filename:)` helper shared by the existing `prepareImageData(_:mealLogId:)` and the new `prepareProfileImageData(_:userId:)` (declared on `ImageServiceProtocol` too), which prefixes the filename (`profile_<uuid>`) to avoid colliding with meal-log photos in the same `Images/` directory.
  - Injected `userProfileRepository` into `AppContainer`.
  - Added `Features/Profile/ViewModels/ProfileViewModel.swift` (`@MainActor @Observable`, same pattern as `DashboardViewModel`): loads the local profile by `userId` on `.task`. `ProfileView` now constructs it (same lazy-`@State` pattern as `DashboardView`) and reads `displayName`/photo thumbnail from it, falling back to `AppViewModel.userDisplayName` while no local profile exists yet. `AppViewModel` still owns session/auth state (email, auth state, sign-out); `ProfileViewModel` is the new source of truth for editable profile data, ready for Phase B.
- **Phase 4 — Visual redesign of `Features/MealLogging/Views/`**:
  - Added a step progress indicator: `MealLoggingViewModel.Step` gained `index`/`Step.totalSteps`, and `MealLoggingFlowView` renders a 4-segment progress bar + "Paso X de 4" below the nav title, hidden once `isSaved`.
  - Added transitions between steps: `.transition(.asymmetric(...))` + `.animation` on the step `switch` in `MealLoggingFlowView`.
  - Added haptics on key actions: `UIImpactFeedbackGenerator(.light)` when adding/removing a food in `FoodSearchView` (chip tap, row tap, custom-food alert), `UINotificationFeedbackGenerator(.success)` after a successful save in `MealLogReviewView` (the achievement-unlock haptic already existed in `AchievementCelebrationView`).
  - Tap-target pass on the Phase 1 quantity/unit controls: confirmed the unit `Menu` (`minHeight: 44`) and native `Stepper` already meet 44×44pt; added `minHeight: 44` to the "Quitar foto" button, which was undersized.
  - Verified end-to-end in the iOS Simulator (logged-in session): progress bar advances 1→4, "Continuar sin foto"/"Continuar" label still switches correctly per the Phase 1 fix, food add/remove and save all completed without regressions.
- **Phase 1.5 — Urgent bug fix: could not log a meal against a plan created the same day**:
  - Root cause: `OccurrenceGenerator.occurrences(for:from:userId:)` compared `plan.recurrenceRule.startDate` (stored with the exact creation time) directly against `date` (always normalized to `calendar.startOfDay(for:)` by callers like `DashboardViewModel.loadToday()`). A plan created any time after midnight failed the `startDate <= date` guard for the day it was created, so no occurrence was generated until the next day, regardless of recurrence kind.
  - Fix: normalized the comparison to day granularity — `calendar.startOfDay(for: plan.recurrenceRule.startDate) <= date`. Checked `SwiftDataMealOccurrenceRepository`/`MealOccurrenceRepository` for the same pattern; their `startDate` is an unrelated ranged-fetch parameter already normalized with `startOfDay`, so no further change was needed there.
  - Added `OccurrenceGeneratorTests` (4 cases): daily/once/specificDays plans created late in the day (23:50) still generate today's occurrence, and a plan starting tomorrow does not generate one for today.
- **Phase 3 — Streaks and achievements**:
  - Added `Domain/Models/Achievement.swift` (static catalog of logging-streak, plan-adherence-streak, perfect-week, and volume-milestone achievements), `Streak.swift` (current/longest streak value object per streak type), and `UnlockedAchievement.swift`.
  - Added pure `Domain/Services/StreakCalculator.swift`, reusing the per-day `DailyComplianceSummary`/level computation from Phase 2 instead of duplicating it. Covered with `StreakCalculatorTests` (continuous streak, broken streak, single-day streak, streak still alive when today has no entry yet but yesterday did, zero streak when the most recent active day is older than yesterday, plan-adherence streak reusing `DailyComplianceCalculator`).
  - Added `Domain/RepositoryProtocols/AchievementRepository.swift` + `Data/RepositoryImplementations/SwiftDataAchievementRepository.swift`, following the `SwiftDataMealLogRepository` pattern, and wired it into `AppContainer`.
  - Added `Domain/Services/AchievementEvaluator.swift` and `Domain/UseCases/EvaluateAchievementsUseCase.swift`, triggered from `MealLoggingViewModel.saveMealLog()`, exposing newly unlocked achievements for the UI to celebrate.
  - Added `Features/Dashboard/ViewModels/StreakViewModel.swift` + `Features/Dashboard/Views/StreakWidgetView.swift` (🔥 current streak widget) wired into `DashboardView`.
  - Added `Features/Achievements/` (`ViewModels/AchievementsViewModel.swift`, `Views/AchievementsView.swift` badge grid, `Views/AchievementCelebrationView.swift` unlock celebration) and a new tab in `MainTabView`.
- **Phase 2 — Contribution-style compliance heatmap**:
  - Added `Domain/Models/DayComplianceLevel.swift` (5-level `none/low/medium/high/perfect` scale) and `Domain/Models/DailyComplianceSummary.swift` (status + level + completed/total counts).
  - `DailyComplianceCalculator` gained `summary(for:)`, computing status and graded level in one pass over a day's occurrences; the original `status(for:)` now delegates to it, so existing callers are unaffected. Added unit tests covering the none/low/medium/high/perfect boundaries.
  - Added `MealOccurrenceRepository.fetch(from:to:userId:)` (+ `SwiftDataMealOccurrenceRepository` implementation) for a single ranged fetch instead of one query per day.
  - Added `ComplianceHeatmapViewModel` (`Features/Dashboard/ViewModels/`): loads a selectable range (3/6/12 months) with exactly one plans fetch and one ranged occurrence fetch, then computes each day's summary locally by reusing `OccurrenceGenerator` — this is what the Phase 1 dashboard perf fix was in service of.
  - Replaced the old 4-week, 3-color `ComplianceCalendarView` with `ComplianceHeatmapView` (`Features/Dashboard/Views/`): GitHub-style weeks-as-columns grid, rounded square cells colored by level, month labels, a "Menos → Más" legend, horizontal scroll up to 12 months back, and a tap-to-popover tooltip showing the date and "`completed`/`total` comidas completadas".
  - Wired the heatmap into `DashboardView` with a segmented range picker; it loads lazily via its own view model so it no longer sits in `DashboardViewModel.loadToday()`'s critical path. Removed the now-dead `complianceDays`/30-day loop from `DashboardViewModel`.
- **Phase 1 — Meal logging flow fixes**:
  - Fixed `MealLoggingFlowView` "add photo" step: the continue button now reads "Continuar" when a photo was already selected and "Continuar sin foto" only when none was picked, instead of always showing the misleading "sin foto" label.
  - Added per-food quantity/unit input: `MealLoggingViewModel` now tracks a `foodQuantities: [UUID: SelectedFoodQuantity]` map (quantity stepper + unit menu with `porción/g/ml/taza/cucharada/unidad`), rendered per item in `MealLogReviewView`. Values are persisted into `MealLogItem.quantity`/`.unit` in `saveMealLog()` instead of always saving `nil`.
  - Made `eatenAt` editable: replaced the static "Fecha"/"Hora" text rows in `MealLogReviewView` with a compact `DatePicker` so users can correct when they actually ate.
  - Fixed a performance issue in `DashboardViewModel.loadToday()`: the 30-day compliance loop called `mealPlanRepository.fetchActive(for:)` on every iteration; it now fetches active plans once and reuses them for both today's occurrences and the historical loop. This is the performance baseline Phase 2's longer-range heatmap (up to 1 year) depends on.
  - Propagated `errorMessage` across the whole flow: `MealLoggingFlowView` now renders a shared error banner above every step (not just the review step), and the photo picker sets `errorMessage` if loading the selected image fails instead of silently discarding the error.
- Created the initial architecture folders from `06-APPLICATION-ARCHITECTURE.md`.
- Added pure Domain models, value objects, enums, and fundamental states for Foundation.
- Added pure domain service `DailyComplianceCalculator`.
- Added initial repository protocols:
  - `MealPlanRepository`
  - `MealOccurrenceRepository`
  - `MealLogRepository`
  - `FoodCatalogRepository`
- Added initial infrastructure/data protocols needed by the basic container.
- Added basic `AppContainer`.
- Replaced the Xcode template `ContentView` with a minimal Foundation root view.
- Added unit tests for domain compliance and value objects.
- Apple signing configured and verified with a signed generic iOS build.
- Firebase project setup completed manually by the user:
  - iOS app registered for bundle identifier `com.addydx.Savra`.
  - Firebase Authentication Email/Password enabled.
  - Cloud Firestore created in Production mode.
- Integrated Firebase Foundation infrastructure:
  - Added Firebase Swift Package dependency.
  - Linked only `FirebaseCore`.
  - Added `GoogleService-Info.plist` to the app bundle.
  - Added minimal Firebase bootstrap at app startup.
  - Added a Foundation test that verifies Firebase configures from the bundled plist.
- Updated deployment target to iOS 17.0 for `Savra`, `SavraTests`, and `SavraUITests`.

## In Progress

- None. Both prompts in `Documentation/` (`PROMPT-claude-code-meal-logging-streaks.md`, `PROMPT-claude-code-account-personalization.md`) are fully implemented.

## Pending

- Firestore business data access, collections, rules hardening, and sync behavior in later phases.

## Manual Actions Required

- None remaining for Phase 0.

## Blockers

- None remaining for Phase 0.

## Pending Decisions

- None outstanding. Account deletion strategy was resolved in ADR-009 (`Documentation/ADR-009-account-deletion.md`).

## Verifications Performed

- `plutil -lint Savra/Savra/GoogleService-Info.plist`
  - Result: OK.
- `xcodebuild -project Savra/Savra.xcodeproj -resolvePackageDependencies -scheme Savra -derivedDataPath /tmp/savra-derived-data`
  - Result: succeeded after clearing corrupted local SwiftPM artifact cache entries.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/savra-derived-data build`
  - Result: succeeded.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination generic/platform=iOS -derivedDataPath /tmp/savra-derived-data build`
  - Result: succeeded with Apple Development signing.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/savra-derived-data -only-testing:SavraTests test`
  - Result: succeeded. Seven unit tests passed.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/savra-derived-data -only-testing:SavraUITests/SavraUITestsLaunchTests/testLaunch test`
  - Result: succeeded. Launch test passed on all generated launch-test variants.
- `xcodebuild -project Savra/Savra.xcodeproj -showBuildSettings -target Savra`
  - Result: effective `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.
- `xcodebuild -project Savra/Savra.xcodeproj -showBuildSettings -target SavraTests`
  - Result: effective `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.
- `xcodebuild -project Savra/Savra.xcodeproj -showBuildSettings -target SavraUITests`
  - Result: effective `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.
- `rg -n "import (Firebase|FirebaseAuth|FirebaseFirestore|SwiftData|SwiftUI|UIKit)" Savra/Savra/Domain`
  - Result: no forbidden imports found in Domain.
- `find Savra -name GoogleService-Info.plist -print`
  - Result: one repository copy found at `Savra/Savra/GoogleService-Info.plist`.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings (Phase 1 meal logging fixes).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all existing unit tests still pass (Phase 1 meal logging fixes).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, only pre-existing unrelated warning remains (`CreateAccountView.swift`) — no new warnings from the Phase 2 heatmap.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, including 5 new `DailyComplianceCalculatorTests` cases for the none/low/medium/high/perfect level boundaries (Phase 2).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded (Phase 1.5 `OccurrenceGenerator` date-normalization fix).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, including 4 new `OccurrenceGeneratorTests` cases (late-day plan creation for daily/once/specificDays recurrence, plus a plan starting tomorrow) alongside the existing `StreakCalculatorTests` and `DailyComplianceCalculatorTests` suites (Phase 1.5).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings (Phase 4 visual redesign — progress bar, transitions, haptics, tap targets).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase 4 touched only Views/ViewModel UI concerns, no domain logic changed).
- Manual verification in the iOS Simulator (logged-in test account): full meal logging flow (select plan → photo → search food → review → save) exercised end-to-end; progress bar advanced "Paso 1 de 4" → "Paso 4 de 4", food add/remove worked with the selected-foods chip bar, save completed and returned to the Dashboard.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded (Account Personalization Phase A — `SDUserProfile`, `UserProfileRepository`, `ProfileViewModel`, generalized image service).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase A added persistence/DI plumbing, no domain logic changed, so no new tests needed).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings after fixing a Swift concurrency warning in `EditProfileView` (Account Personalization Phase B).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase B).
- Manual verification in the iOS Simulator (logged-in test account): edited display name via `EditProfileView`, saved, confirmed `ProfileView` updated immediately without a restart, then force-quit and relaunched the app and confirmed the new name persisted from `SDUserProfile`.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings (Account Personalization Phase C — reauthenticate/updateEmail/updatePassword, `SecuritySectionView`). Note: this build only compiles `SimulatorAuthService`'s stubs and `AuthServiceProtocol`/`AuthError` changes; `FirebaseAuthService`'s real branch is gated behind `#if !targetEnvironment(simulator)` and isn't exercised here.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase C).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings (Account Personalization Phase D — `AppPreferences`, `PreferencesStore`/`ThemeSettings`, `PreferencesSectionView`, wiring into `MealLoggingViewModel`/`MealPlanFormView`).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase D).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, no new warnings (Account Personalization Phase E — `DeleteAccountUseCase`, repo `deleteAll`/`delete(userId:)` methods, `DeleteAccountView`). Same `#if !targetEnvironment(simulator)` caveat as Phase C applies to `FirebaseAuthService.deleteAccount()`.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, all 24 existing tests still pass (Phase E).

## Last Build Result

Succeeded for simulator build after Account Personalization Phase E — all 5 phases of the account personalization prompt are now complete.

## Last Test Result

Succeeded after Account Personalization Phase E:

- `OccurrenceGeneratorTests`, `StreakCalculatorTests`, `DailyComplianceCalculatorTests`, `DomainValueObjectTests`, and `FirebaseBootstrapTests` all passed on `SavraTests` (24 tests, no regressions).
