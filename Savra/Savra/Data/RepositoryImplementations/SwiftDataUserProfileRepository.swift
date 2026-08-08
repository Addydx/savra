import Foundation
import SwiftData

final class SwiftDataUserProfileRepository: @unchecked Sendable, UserProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(userId: UUID) async throws -> UserProfile? {
        let uid = userId.uuidString
        let predicate = #Predicate<SDUserProfile> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDUserProfile>(predicate: predicate)
        return try context.fetch(descriptor).first?.toDomain()
    }

    func upsert(_ profile: UserProfile) async throws {
        let uid = profile.userId.uuidString
        let predicate = #Predicate<SDUserProfile> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDUserProfile>(predicate: predicate)

        if let existing = try context.fetch(descriptor).first {
            existing.displayName = profile.displayName
            existing.photoLocalPath = profile.photoLocalPath
            existing.photoThumbnailPath = profile.photoThumbnailPath
            existing.updatedAt = profile.updatedAt
        } else {
            context.insert(SDUserProfile.fromDomain(profile))
        }
        try context.save()
    }

    func delete(userId: UUID) async throws {
        let uid = userId.uuidString
        let predicate = #Predicate<SDUserProfile> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDUserProfile>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { return }
        context.delete(existing)
        try context.save()
    }
}
