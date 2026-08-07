# Implementation Status

## Current Phase

Phase 4 — Visual redesign of `Features/MealLogging/Views/` (next up)

## Completed

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

- None for Phase 0.

## Pending

- Firestore business data access, collections, rules hardening, and sync behavior in later phases.
- Account deletion strategy, intentionally deferred until the corresponding future phase.
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
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded, only pre-existing unrelated warning remains (`CreateAccountView.swift`) — no new warnings from the Phase 2 heatmap.
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, including 5 new `DailyComplianceCalculatorTests` cases for the none/low/medium/high/perfect level boundaries (Phase 2).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' build`
  - Result: succeeded (Phase 1.5 `OccurrenceGenerator` date-normalization fix).
- `xcodebuild -project Savra/Savra.xcodeproj -scheme Savra -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SavraTests test`
  - Result: succeeded, including 4 new `OccurrenceGeneratorTests` cases (late-day plan creation for daily/once/specificDays recurrence, plus a plan starting tomorrow) alongside the existing `StreakCalculatorTests` and `DailyComplianceCalculatorTests` suites (Phase 1.5).

## Last Build Result

Succeeded for simulator build after the Phase 1.5 `OccurrenceGenerator` fix.

## Last Test Result

Succeeded after the Phase 1.5 fix:

- `OccurrenceGeneratorTests` (new), `StreakCalculatorTests`, `DailyComplianceCalculatorTests`, `DomainValueObjectTests`, and `FirebaseBootstrapTests` all passed on `SavraTests`.
