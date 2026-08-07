import Foundation
import SwiftData

final class SwiftDataAchievementRepository: @unchecked Sendable, AchievementRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchUnlocked(for userId: UUID) async throws -> [UnlockedAchievement] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDUnlockedAchievement> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDUnlockedAchievement>(predicate: predicate)
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func unlock(_ achievementId: String, for userId: UUID, at date: Date) async throws -> UnlockedAchievement {
        let uid = userId.uuidString
        let aid = achievementId
        let predicate = #Predicate<SDUnlockedAchievement> { $0.userId == uid && $0.achievementId == aid }
        let descriptor = FetchDescriptor<SDUnlockedAchievement>(predicate: predicate)

        if let existing = try context.fetch(descriptor).first {
            return existing.toDomain()
        }

        let new = SDUnlockedAchievement(userId: uid, achievementId: achievementId, unlockedAt: date)
        context.insert(new)
        try context.save()
        return new.toDomain()
    }
}
