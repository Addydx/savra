import Foundation

protocol MealPlanRepository: Sendable {
    func create(_ plan: MealPlan) async throws
    func update(_ plan: MealPlan) async throws
    func delete(id: MealPlan.ID) async throws
    func fetchActive(for userId: User.ID) async throws -> [MealPlan]
}
