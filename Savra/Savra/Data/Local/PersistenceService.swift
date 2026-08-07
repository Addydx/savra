import Foundation
import SwiftData

final class PersistenceService {
    static let shared = PersistenceService()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            SDMealPlan.self,
            SDMealOccurrence.self,
            SDMealLog.self,
            SDMealLogItem.self,
            SDMealLogPhoto.self,
            SDFoodItem.self,
            SDUnlockedAchievement.self,
        ])
        container = try! ModelContainer(for: schema)
    }

    var context: ModelContext {
        container.mainContext
    }

    func save() {
        try? context.save()
    }
}
