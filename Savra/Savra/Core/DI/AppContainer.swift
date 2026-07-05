import Foundation

struct AppContainer: Sendable {
    var authService: (any AuthServiceProtocol)?
    var mealPlanRepository: (any MealPlanRepository)?
    var mealLogRepository: (any MealLogRepository)?
    var foodCatalogRepository: (any FoodCatalogRepository)?
    var notificationScheduler: (any NotificationSchedulerProtocol)?
    var imageService: (any ImageServiceProtocol)?
    var syncEngine: (any SyncEngineProtocol)?

    static let foundation = AppContainer()
}
