import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let persistence: PersistenceService
    let authService: any AuthServiceProtocol
    let mealPlanRepository: SwiftDataMealPlanRepository
    let mealOccurrenceRepository: SwiftDataMealOccurrenceRepository
    let mealLogRepository: SwiftDataMealLogRepository
    let foodCatalogRepository: LocalFoodCatalogRepository
    let achievementRepository: SwiftDataAchievementRepository
    let userProfileRepository: SwiftDataUserProfileRepository
    let imageService: LocalImageService
    let preferencesStore: any PreferencesStore
    let themeSettings: ThemeSettings
    let evaluateAchievementsUseCase: EvaluateAchievementsUseCase
    let deleteAccountUseCase: DeleteAccountUseCase

    init() {
        let persistence = PersistenceService.shared
        self.persistence = persistence
        #if targetEnvironment(simulator)
        self.authService = SimulatorAuthService()
        #else
        self.authService = FirebaseAuthService()
        #endif
        let context = persistence.context
        self.mealPlanRepository = SwiftDataMealPlanRepository(context: context)
        self.mealOccurrenceRepository = SwiftDataMealOccurrenceRepository(context: context)
        self.mealLogRepository = SwiftDataMealLogRepository(context: context)
        self.foodCatalogRepository = LocalFoodCatalogRepository(context: context)
        self.achievementRepository = SwiftDataAchievementRepository(context: context)
        self.userProfileRepository = SwiftDataUserProfileRepository(context: context)
        self.imageService = LocalImageService()
        let preferencesStore = UserDefaultsPreferencesStore()
        self.preferencesStore = preferencesStore
        self.themeSettings = ThemeSettings(theme: preferencesStore.load().theme)
        self.evaluateAchievementsUseCase = EvaluateAchievementsUseCase(
            mealPlanRepository: mealPlanRepository,
            mealOccurrenceRepository: mealOccurrenceRepository,
            mealLogRepository: mealLogRepository,
            achievementRepository: achievementRepository
        )
        self.deleteAccountUseCase = DeleteAccountUseCase(
            mealPlanRepository: mealPlanRepository,
            mealOccurrenceRepository: mealOccurrenceRepository,
            mealLogRepository: mealLogRepository,
            achievementRepository: achievementRepository,
            userProfileRepository: userProfileRepository,
            imageService: imageService,
            authService: authService
        )
    }
}
