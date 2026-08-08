import Foundation

protocol MealOccurrenceRepository: Sendable {
    func create(_ occurrence: MealOccurrence) async throws
    func update(_ occurrence: MealOccurrence) async throws
    func fetch(for mealPlanId: MealPlan.ID) async throws -> [MealOccurrence]
    func fetch(on date: Date, userId: User.ID) async throws -> [MealOccurrence]
    func fetch(from startDate: Date, to endDate: Date, userId: User.ID) async throws -> [MealOccurrence]
    func upsert(for planId: MealPlan.ID, on date: Date, userId: User.ID, status: MealOccurrence.Status, timeHour: Int?, timeMinute: Int?) async throws -> MealOccurrence
    func deleteAll(for userId: User.ID) async throws
}
