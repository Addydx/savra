import Foundation

/// Orchestrates streak/achievement evaluation. Depends only on repository protocols (Domain
/// types), so it stays free of SwiftData/Firebase imports like the rest of Domain.
struct EvaluateAchievementsUseCase: Sendable {
    struct ProgressSnapshot: Sendable {
        let loggingStreak: Streak
        let planAdherenceStreak: Streak
        let totalMealsLogged: Int
        let isCurrentWeekPerfect: Bool
    }

    private let mealPlanRepository: any MealPlanRepository
    private let mealOccurrenceRepository: any MealOccurrenceRepository
    private let mealLogRepository: any MealLogRepository
    private let achievementRepository: any AchievementRepository
    private let streakCalculator = StreakCalculator()
    private let complianceCalculator = DailyComplianceCalculator()

    init(
        mealPlanRepository: any MealPlanRepository,
        mealOccurrenceRepository: any MealOccurrenceRepository,
        mealLogRepository: any MealLogRepository,
        achievementRepository: any AchievementRepository
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.mealOccurrenceRepository = mealOccurrenceRepository
        self.mealLogRepository = mealLogRepository
        self.achievementRepository = achievementRepository
    }

    /// Computes current streaks/counters in a single pass (one plans fetch, one ranged
    /// occurrence fetch, one logs fetch), reusing Phase 2's `DailyComplianceCalculator` per day.
    /// Used both to evaluate new unlocks and to render progress on the Achievements screen.
    func currentProgress(for userId: UUID, referenceDate: Date = Date(), historyDays: Int = 400) async throws -> ProgressSnapshot {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: referenceDate)
        guard let rangeStart = calendar.date(byAdding: .day, value: -(historyDays - 1), to: todayStart) else {
            return ProgressSnapshot(
                loggingStreak: Streak(type: .logging, currentStreak: 0, longestStreak: 0, lastActiveDate: nil),
                planAdherenceStreak: Streak(type: .planAdherence, currentStreak: 0, longestStreak: 0, lastActiveDate: nil),
                totalMealsLogged: 0,
                isCurrentWeekPerfect: false
            )
        }

        let plans = try await mealPlanRepository.fetchActive(for: userId)
        let persisted = try await mealOccurrenceRepository.fetch(from: rangeStart, to: todayStart, userId: userId)
        let persistedByDay = Dictionary(grouping: persisted) { calendar.startOfDay(for: $0.scheduledDate) }

        var dailyOccurrences: [Date: [MealOccurrence]] = [:]
        var cursor = rangeStart
        while cursor <= todayStart {
            let computed = OccurrenceGenerator.occurrences(for: cursor, from: plans, userId: userId)
            let persistedForDay = persistedByDay[cursor] ?? []
            var merged: [MealOccurrence] = []
            for plan in plans {
                if let pers = persistedForDay.first(where: { $0.mealPlanId == plan.id }) {
                    merged.append(pers)
                } else if let comp = computed.first(where: { $0.mealPlanId == plan.id }) {
                    merged.append(comp)
                }
            }
            dailyOccurrences[cursor] = merged
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        let planAdherenceStreak = streakCalculator.planAdherenceStreak(dailyOccurrences: dailyOccurrences, referenceDate: referenceDate)

        let logs = try await mealLogRepository.fetchAll(for: userId)
        let loggedDates = logs.map { $0.0.eatenAt }
        let loggingStreak = streakCalculator.loggingStreak(loggedDates: loggedDates, referenceDate: referenceDate)

        let isCurrentWeekPerfect = Self.isCurrentWeekPerfect(
            referenceDate: todayStart,
            dailyOccurrences: dailyOccurrences,
            calculator: complianceCalculator,
            calendar: calendar
        )

        return ProgressSnapshot(
            loggingStreak: loggingStreak,
            planAdherenceStreak: planAdherenceStreak,
            totalMealsLogged: logs.count,
            isCurrentWeekPerfect: isCurrentWeekPerfect
        )
    }

    /// Evaluates all achievement conditions and persists any newly unlocked ones.
    /// Returns just the newly unlocked achievements so the UI can show a celebration.
    @discardableResult
    func evaluate(for userId: UUID, referenceDate: Date = Date(), historyDays: Int = 400) async throws -> [Achievement] {
        let snapshot = try await currentProgress(for: userId, referenceDate: referenceDate, historyDays: historyDays)
        let input = AchievementEvaluationInput(
            loggingStreak: snapshot.loggingStreak,
            planAdherenceStreak: snapshot.planAdherenceStreak,
            totalMealsLogged: snapshot.totalMealsLogged,
            isCurrentWeekPerfect: snapshot.isCurrentWeekPerfect
        )

        let alreadyUnlocked = Set(try await achievementRepository.fetchUnlocked(for: userId).map(\.achievementId))
        let newlyUnlocked = AchievementEvaluator().evaluate(input: input, alreadyUnlockedIds: alreadyUnlocked)

        for achievement in newlyUnlocked {
            _ = try await achievementRepository.unlock(achievement.id, for: userId, at: referenceDate)
        }

        return newlyUnlocked
    }

    /// A week is "perfect" only once every one of its 7 days has happened (no future days) and
    /// every day that had required occurrences was fully completed.
    private static func isCurrentWeekPerfect(
        referenceDate: Date,
        dailyOccurrences: [Date: [MealOccurrence]],
        calculator: DailyComplianceCalculator,
        calendar: Calendar
    ) -> Bool {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return false }
        var day = calendar.startOfDay(for: weekInterval.start)
        let weekEnd = calendar.startOfDay(for: weekInterval.end)
        var hasRequiredDay = false

        while day < weekEnd {
            guard day <= referenceDate, let occurrences = dailyOccurrences[day] else { return false }
            if !occurrences.isEmpty {
                hasRequiredDay = true
                if calculator.status(for: occurrences) == .incomplete { return false }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        return hasRequiredDay
    }
}
