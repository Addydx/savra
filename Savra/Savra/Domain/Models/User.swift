import Foundation

struct User: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var email: String
    let createdAt: Date
}
