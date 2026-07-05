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
