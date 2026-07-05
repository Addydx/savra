import Foundation

struct MealLogItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let mealLogId: UUID
    let foodItemId: UUID
    var displayName: String
    var quantity: Double?
    var unit: String?
}
