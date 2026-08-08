import Foundation

struct UserProfile: Identifiable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var displayName: String
    var photoLocalPath: String?
    var photoThumbnailPath: String?
    let createdAt: Date
    var updatedAt: Date
}
