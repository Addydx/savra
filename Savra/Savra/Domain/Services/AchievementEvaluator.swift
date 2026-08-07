import Foundation

struct AchievementEvaluationInput: Sendable {
    let loggingStreak: Streak
    let planAdherenceStreak: Streak
    let totalMealsLogged: Int
    let isCurrentWeekPerfect: Bool
}

struct AchievementEvaluator: Sendable {
    /// Returns achievements whose condition is now satisfied and that aren't already unlocked.
    func evaluate(input: AchievementEvaluationInput, alreadyUnlockedIds: Set<String>) -> [Achievement] {
        Achievement.all.filter { achievement in
            guard !alreadyUnlockedIds.contains(achievement.id) else { return false }
            return isSatisfied(achievement.condition, input: input)
        }
    }

    private func isSatisfied(_ condition: AchievementCondition, input: AchievementEvaluationInput) -> Bool {
        switch condition {
        case .loggingStreak(let days):
            return input.loggingStreak.currentStreak >= days
        case .planAdherenceStreak(let days):
            return input.planAdherenceStreak.currentStreak >= days
        case .perfectWeek:
            return input.isCurrentWeekPerfect
        case .totalMealsLogged(let count):
            return input.totalMealsLogged >= count
        }
    }
}
