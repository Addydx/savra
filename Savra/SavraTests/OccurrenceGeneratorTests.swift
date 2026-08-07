import Foundation
import Testing
@testable import Savra

struct OccurrenceGeneratorTests {
    private let calendar = Calendar.current
    private let userId = UUID()

    @Test func planCreatedLateTodayWithDailyRecurrenceGeneratesOccurrenceForToday() {
        let today = calendar.startOfDay(for: Date())
        let createdAt = calendar.date(bySettingHour: 23, minute: 50, second: 0, of: today)!
        let plan = makePlan(kind: .daily, startDate: createdAt)

        let occurrences = OccurrenceGenerator.occurrences(for: today, from: [plan], userId: userId)

        #expect(!occurrences.isEmpty)
    }

    @Test func planCreatedLateTodayWithOnceRecurrenceGeneratesOccurrenceForToday() {
        let today = calendar.startOfDay(for: Date())
        let createdAt = calendar.date(bySettingHour: 23, minute: 50, second: 0, of: today)!
        let plan = makePlan(kind: .once, startDate: createdAt)

        let occurrences = OccurrenceGenerator.occurrences(for: today, from: [plan], userId: userId)

        #expect(!occurrences.isEmpty)
    }

    @Test func planCreatedLateTodayWithSpecificDaysRecurrenceGeneratesOccurrenceForToday() {
        let today = calendar.startOfDay(for: Date())
        let createdAt = calendar.date(bySettingHour: 23, minute: 50, second: 0, of: today)!
        let todayWeekday = Weekday(rawValue: calendar.component(.weekday, from: today))!
        let plan = makePlan(kind: .specificDays, daysOfWeek: [todayWeekday], startDate: createdAt)

        let occurrences = OccurrenceGenerator.occurrences(for: today, from: [plan], userId: userId)

        #expect(!occurrences.isEmpty)
    }

    @Test func planStartingTomorrowDoesNotGenerateOccurrenceForToday() {
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let plan = makePlan(kind: .daily, startDate: tomorrow)

        let occurrences = OccurrenceGenerator.occurrences(for: today, from: [plan], userId: userId)

        #expect(occurrences.isEmpty)
    }

    private func makePlan(
        kind: RecurrenceRule.Kind,
        daysOfWeek: Set<Weekday>? = nil,
        startDate: Date
    ) -> MealPlan {
        MealPlan(
            id: UUID(),
            userId: userId,
            name: "Test Plan",
            emoji: nil,
            scheduleKind: .routine,
            time: nil,
            recurrenceRule: RecurrenceRule(kind: kind, daysOfWeek: daysOfWeek, startDate: startDate),
            notificationsEnabled: false,
            isActive: true,
            createdAt: startDate,
            updatedAt: startDate
        )
    }
}
