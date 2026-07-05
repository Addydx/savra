import Foundation

protocol MealOccurrenceRepository: Sendable {
    func create(_ occurrence: MealOccurrence) async throws
    func update(_ occurrence: MealOccurrence) async throws
    func fetch(for mealPlanId: MealPlan.ID) async throws -> [MealOccurrence]
    func fetch(on date: Date, userId: User.ID) async throws -> [MealOccurrence]
}
