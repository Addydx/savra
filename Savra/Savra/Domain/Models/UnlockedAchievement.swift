import Foundation

struct UnlockedAchievement: Identifiable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    let achievementId: String
    let unlockedAt: Date
}
