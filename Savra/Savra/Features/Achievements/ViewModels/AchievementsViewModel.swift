import Foundation
import SwiftUI

@MainActor
@Observable
final class AchievementsViewModel {
    struct AchievementDisplay: Identifiable {
        let achievement: Achievement
        let isUnlocked: Bool
        let unlockedAt: Date?
        let progressCurrent: Int
        let progressTarget: Int
        var id: String { achievement.id }
    }

    var items: [AchievementDisplay] = []
    var isLoading = true

    private let container: AppContainer
    private let userId: String

    init(container: AppContainer, userId: String) {
        self.container = container
        self.userId = userId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let userIdUUID = UUID(uuidString: userId) ?? UUID()
        do {
            let unlocked = try await container.achievementRepository.fetchUnlocked(for: userIdUUID)
            let unlockedById = Dictionary(uniqueKeysWithValues: unlocked.map { ($0.achievementId, $0) })
            let snapshot = try await container.evaluateAchievementsUseCase.currentProgress(for: userIdUUID)

            items = Achievement.all.map { achievement in
                let unlockedEntry = unlockedById[achievement.id]
                let (current, target) = Self.progress(for: achievement.condition, snapshot: snapshot)
                return AchievementDisplay(
                    achievement: achievement,
                    isUnlocked: unlockedEntry != nil,
                    unlockedAt: unlockedEntry?.unlockedAt,
                    progressCurrent: current,
                    progressTarget: target
                )
            }
        } catch {
            items = Achievement.all.map {
                AchievementDisplay(achievement: $0, isUnlocked: false, unlockedAt: nil, progressCurrent: 0, progressTarget: 1)
            }
        }
    }

    private static func progress(
        for condition: AchievementCondition,
        snapshot: EvaluateAchievementsUseCase.ProgressSnapshot
    ) -> (current: Int, target: Int) {
        switch condition {
        case .loggingStreak(let days):
            return (min(snapshot.loggingStreak.currentStreak, days), days)
        case .planAdherenceStreak(let days):
            return (min(snapshot.planAdherenceStreak.currentStreak, days), days)
        case .perfectWeek:
            return (snapshot.isCurrentWeekPerfect ? 1 : 0, 1)
        case .totalMealsLogged(let count):
            return (min(snapshot.totalMealsLogged, count), count)
        }
    }
}
