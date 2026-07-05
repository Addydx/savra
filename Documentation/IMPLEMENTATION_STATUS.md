# Implementation Status

## Current Phase

Phase 0 — Foundation

## Completed

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

- Firebase Authentication behavior and UI, scheduled for Phase 1.
- Firestore business data access, collections, rules hardening, and sync behavior in later phases.
- Firebase Storage integration in the phase that introduces meal photos.
- SwiftData local models, intentionally outside the current Foundation completion.
- Account deletion strategy, intentionally deferred until the corresponding future phase.

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

## Last Build Result

Succeeded for simulator and signed generic iOS builds.

## Last Test Result

Succeeded for Phase 0 tests:

- Seven `SavraTests` unit tests passed.
- `SavraUITestsLaunchTests.testLaunch()` passed on all generated launch-test variants.
