import Foundation

struct MealLog: Identifiable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var mealOccurrenceId: UUID?
    var eatenAt: Date
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
}
