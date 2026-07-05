import Foundation

struct MealOccurrence: Identifiable, Equatable, Sendable {
    enum Status: String, Equatable, Sendable {
        case scheduled
        case completed
        case skipped
        case missed
    }

    let id: UUID
    let mealPlanId: UUID
    var scheduledDate: Date
    var scheduledTime: MealTime?
    var isRequired: Bool
    var status: Status
    var completedAt: Date?
}
