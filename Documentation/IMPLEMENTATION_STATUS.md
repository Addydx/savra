# Implementation Status

## Current Phase

Phase 1 — Meal logging flow fixes (constancy/achievements roadmap in progress)

## Completed

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

- None for Phase 0.

## Pending

- Firestore business data access, collections, rules hardening, and sync behavior in later phases.
- Account deletion strategy, intentionally deferred until the corresponding future phase.
- **Phase 2** — GitHub-style contribution heatmap for compliance (replace the 4-week `ComplianceCalendarView` with a leveled, scrollable multi-month heatmap; needs a `DayComplianceLevel`/percentage calculation and a ranged fetch on `MealOccurrenceRepository`).
- **Phase 3** — Streaks and achievements (new `Domain/Models/Achievement.swift`, `Streak.swift`, `UnlockedAchievement.swift`, `StreakCalculator`, `AchievementRepository`, `AchievementEvaluator`, `Features/Achievements/`, streak widget on `DashboardView`, unlock celebration).
- **Phase 4** — Visual redesign of `Features/MealLogging/Views/` (step progress indicator, haptics, transitions, contrast/tap-target pass).

## Manual Actions Required

- None remaining for Phase 0.

## Blockers

- None remaining for Phase 0.

## Pending Decisions

- Account deletion implementation strategy remains deferred. Current direction is to evaluate an official Firebase-supported approach when the feature is scheduled.

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

## Last Build Result

Succeeded for simulator build after Phase 1 meal logging fixes.

## Last Test Result

Succeeded after Phase 1 meal logging fixes:

- `DailyComplianceCalculatorTests`, `DomainValueObjectTests`, and `FirebaseBootstrapTests` all passed on `SavraTests`.
