import Foundation

enum StreakType: String, Equatable, Sendable {
    /// At least one meal logged that day.
    case logging
    /// All required MealOccurrences for that day completed.
    case planAdherence
}

struct Streak: Equatable, Sendable {
    let type: StreakType
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: Date?
}
