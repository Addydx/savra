import Foundation

protocol AchievementRepository: Sendable {
    func fetchUnlocked(for userId: User.ID) async throws -> [UnlockedAchievement]
    func unlock(_ achievementId: String, for userId: User.ID, at date: Date) async throws -> UnlockedAchievement
}
