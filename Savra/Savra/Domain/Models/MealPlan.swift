import Foundation

struct MealPlan: Identifiable, Equatable, Sendable {
    enum ScheduleKind: String, Equatable, Sendable {
        case routine
        case oneTimeGoal
        case scheduledMeal
    }

    let id: UUID
    let userId: UUID
    var name: String
    var emoji: String?
    var scheduleKind: ScheduleKind
    var time: MealTime?
    var recurrenceRule: RecurrenceRule
    var notificationsEnabled: Bool
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
}
