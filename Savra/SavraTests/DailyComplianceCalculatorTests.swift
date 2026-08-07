import Foundation
import Testing
@testable import Savra

struct DailyComplianceCalculatorTests {
    private let calculator = DailyComplianceCalculator()

    @Test func dayWithoutOccurrencesIsNeutral() {
        #expect(calculator.status(for: []) == .neutral)
    }

    @Test func completedRequiredOccurrencesAchieveTheDay() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .completed)
        ]

        #expect(calculator.status(for: occurrences) == .achieved)
    }

    @Test func anyIncompleteRequiredOccurrenceMakesTheDayIncomplete() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .scheduled)
        ]

        #expect(calculator.status(for: occurrences) == .incomplete)
    }

    @Test func optionalOccurrencesDoNotBlockAchievement() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .scheduled, isRequired: false)
        ]

        #expect(calculator.status(for: occurrences) == .achieved)
    }

    @Test func dayWithoutOccurrencesHasNoneLevel() {
        let summary = calculator.summary(for: [])
        #expect(summary.level == .none)
        #expect(summary.completedCount == 0)
        #expect(summary.totalCount == 0)
    }

    @Test func fullyCompletedDayHasPerfectLevel() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .completed)
        ]

        let summary = calculator.summary(for: occurrences)
        #expect(summary.level == .perfect)
        #expect(summary.completedCount == 2)
        #expect(summary.totalCount == 2)
    }

    @Test func zeroOfThreeRequiredCompletedHasNoneLevel() {
        let occurrences = [
            makeOccurrence(status: .scheduled),
            makeOccurrence(status: .scheduled),
            makeOccurrence(status: .scheduled)
        ]

        let summary = calculator.summary(for: occurrences)
        #expect(summary.level == .none)
        #expect(summary.totalCount == 3)
    }

    @Test func oneOfFourRequiredCompletedHasLowLevel() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .scheduled),
            makeOccurrence(status: .scheduled),
            makeOccurrence(status: .scheduled)
        ]

        #expect(calculator.summary(for: occurrences).level == .low)
    }

    @Test func twoOfThreeRequiredCompletedHasHighLevel() {
        let occurrences = [
            makeOccurrence(status: .completed),
            makeOccurrence(status: .completed),
            makeOccurrence(status: .scheduled)
        ]

        #expect(calculator.summary(for: occurrences).level == .high)
    }

    private func makeOccurrence(
        status: MealOccurrence.Status,
        isRequired: Bool = true
    ) -> MealOccurrence {
        MealOccurrence(
            id: UUID(),
            mealPlanId: UUID(),
            scheduledDate: Date(),
            scheduledTime: nil,
            isRequired: isRequired,
            status: status,
            completedAt: status == .completed ? Date() : nil
        )
    }
}
