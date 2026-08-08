import Foundation

protocol UserProfileRepository: Sendable {
    func fetch(userId: User.ID) async throws -> UserProfile?
    func upsert(_ profile: UserProfile) async throws
}
