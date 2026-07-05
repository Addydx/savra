import Foundation

struct FoodItem: Identifiable, Equatable, Sendable {
    enum Source: String, Equatable, Sendable {
        case local
        case remote
        case userCreated
    }

    let id: UUID
    var name: String
    var category: String?
    var source: Source
    var ownerUserId: UUID?
}
