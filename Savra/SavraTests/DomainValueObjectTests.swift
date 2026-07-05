import Foundation
import Testing
@testable import Savra

struct DomainValueObjectTests {
    @Test func mealTimeStoresValidHourAndMinute() {
        let time = MealTime(hour: 8, minute: 30)

        #expect(time.hour == 8)
        #expect(time.minute == 30)
    }

    @Test func recurrenceRuleSupportsSpecificDays() {
        let startDate = Date(timeIntervalSince1970: 0)
        let rule = RecurrenceRule(
            kind: .specificDays,
            daysOfWeek: [.monday, .wednesday],
            startDate: startDate
        )

        #expect(rule.startDate == startDate)
        #expect(rule.endDate == nil)
        #expect(rule.kind == .specificDays)
        #expect(rule.daysOfWeek == [.monday, .wednesday])
    }
}
