import Foundation
import Testing
@testable import Savra

struct StreakCalculatorTests {
    private let calculator = StreakCalculator()
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date())

    @Test func noSuccessfulDaysHasZeroStreak() {
        let streak = calculator.streak(type: .logging, successfulDays: [], referenceDate: today)
        #expect(streak.currentStreak == 0)
        #expect(streak.longestStreak == 0)
        #expect(streak.lastActiveDate == nil)
    }

    @Test func continuousStreakEndingTodayCountsEveryDay() {
        let days = days(back: [0, 1, 2, 3, 4])
        let streak = calculator.streak(type: .logging, successfulDays: days, referenceDate: today)
        #expect(streak.currentStreak == 5)
        #expect(streak.longestStreak == 5)
    }

    @Test func brokenStreakOnlyCountsTheMostRecentRun() {
        // Active today and yesterday, then a gap, then an older run.
        let days = days(back: [0, 1, 5, 6, 7])
        let streak = calculator.streak(type: .logging, successfulDays: days, referenceDate: today)
        #expect(streak.currentStreak == 2)
        #expect(streak.longestStreak == 3)
    }

    @Test func singleDayStreakIsOne() {
        let streak = calculator.streak(type: .logging, successfulDays: days(back: [0]), referenceDate: today)
        #expect(streak.currentStreak == 1)
        #expect(streak.longestStreak == 1)
    }

    @Test func streakStillAliveIfYesterdayWasActiveButTodayHasNoEntryYet() {
        // No meal logged yet today, but yesterday and the day before were active.
        let streak = calculator.streak(type: .logging, successfulDays: days(back: [1, 2]), referenceDate: today)
        #expect(streak.currentStreak == 2)
    }

    @Test func streakIsZeroWhenMostRecentActiveDayIsOlderThanYesterday() {
        // Last activity was 3 days ago — the streak is broken even though it existed.
        let streak = calculator.streak(type: .logging, successfulDays: days(back: [3, 4, 5]), referenceDate: today)
        #expect(streak.currentStreak == 0)
        #expect(streak.longestStreak == 3)
    }

    @Test func planAdherenceStreakReusesDailyComplianceCalculatorStatus() {
        let dayZero = today
        guard let dayMinusOne = calendar.date(byAdding: .day, value: -1, to: today) else {
            Issue.record("Failed to compute date")
            return
        }

        let achievedOccurrence = MealOccurrence(
            id: UUID(),
            mealPlanId: UUID(),
            scheduledDate: dayZero,
            scheduledTime: nil,
            isRequired: true,
            status: .completed,
            completedAt: dayZero
        )
        let incompleteOccurrence = MealOccurrence(
            id: UUID(),
            mealPlanId: UUID(),
            scheduledDate: dayMinusOne,
            scheduledTime: nil,
            isRequired: true,
            status: .scheduled,
            completedAt: nil
        )

        let dailyOccurrences: [Date: [MealOccurrence]] = [
            dayZero: [achievedOccurrence],
            dayMinusOne: [incompleteOccurrence]
        ]

        let streak = calculator.planAdherenceStreak(dailyOccurrences: dailyOccurrences, referenceDate: today)
        #expect(streak.currentStreak == 1)
        #expect(streak.type == .planAdherence)
    }

    private func days(back offsets: [Int]) -> Set<Date> {
        Set(offsets.compactMap { calendar.date(byAdding: .day, value: -$0, to: today) })
    }
}
