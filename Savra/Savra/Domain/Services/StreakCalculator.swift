import Foundation

struct StreakCalculator: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Core, type-agnostic streak math over a set of calendar days on which the streak
    /// condition held. The current streak walks backwards from `referenceDate` (or from
    /// yesterday, if today hasn't happened yet) while days remain consecutive.
    func streak(type: StreakType, successfulDays: Set<Date>, referenceDate: Date = Date()) -> Streak {
        guard !successfulDays.isEmpty else {
            return Streak(type: type, currentStreak: 0, longestStreak: 0, lastActiveDate: nil)
        }

        let normalizedDays = Set(successfulDays.map { calendar.startOfDay(for: $0) })
        let sortedDays = normalizedDays.sorted()
        let referenceStart = calendar.startOfDay(for: referenceDate)

        var longestStreak = 0
        var runLength = 0
        var previousDay: Date?
        for day in sortedDays {
            if let previousDay,
               let expectedNext = calendar.date(byAdding: .day, value: 1, to: previousDay),
               expectedNext == day {
                runLength += 1
            } else {
                runLength = 1
            }
            longestStreak = max(longestStreak, runLength)
            previousDay = day
        }

        var cursor = referenceStart
        if !normalizedDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return Streak(type: type, currentStreak: 0, longestStreak: longestStreak, lastActiveDate: sortedDays.last)
            }
            cursor = yesterday
        }

        var currentStreak = 0
        while normalizedDays.contains(cursor) {
            currentStreak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return Streak(type: type, currentStreak: currentStreak, longestStreak: longestStreak, lastActiveDate: sortedDays.last)
    }

    /// Reuses `DailyComplianceCalculator`'s per-day status (from Phase 2's heatmap) instead of
    /// recomputing what counts as a "successful" day for plan adherence.
    func planAdherenceStreak(dailyOccurrences: [Date: [MealOccurrence]], referenceDate: Date = Date()) -> Streak {
        let complianceCalculator = DailyComplianceCalculator()
        let successfulDays = Set(dailyOccurrences.compactMap { date, occurrences -> Date? in
            guard !occurrences.isEmpty else { return nil }
            return complianceCalculator.status(for: occurrences) == .achieved ? calendar.startOfDay(for: date) : nil
        })
        return streak(type: .planAdherence, successfulDays: successfulDays, referenceDate: referenceDate)
    }

    /// A day counts toward the logging streak if at least one meal was logged on it.
    func loggingStreak(loggedDates: [Date], referenceDate: Date = Date()) -> Streak {
        let successfulDays = Set(loggedDates.map { calendar.startOfDay(for: $0) })
        return streak(type: .logging, successfulDays: successfulDays, referenceDate: referenceDate)
    }
}
