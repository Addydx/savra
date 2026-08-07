import Foundation

struct DailyComplianceCalculator: Sendable {
    func status(for occurrences: [MealOccurrence]) -> DayComplianceStatus {
        summary(for: occurrences).status
    }

    /// Computes both the pass/fail status and a graded completion level (used by the
    /// contribution-style heatmap) from a single pass over the day's occurrences.
    func summary(for occurrences: [MealOccurrence]) -> DailyComplianceSummary {
        guard !occurrences.isEmpty else {
            return DailyComplianceSummary(status: .neutral, level: .none, completedCount: 0, totalCount: 0)
        }

        let requiredOccurrences = occurrences.filter(\.isRequired)
        let countedOccurrences = requiredOccurrences.isEmpty ? occurrences : requiredOccurrences
        let completedCount = countedOccurrences.filter { $0.status == .completed }.count
        let totalCount = countedOccurrences.count

        let status: DayComplianceStatus = requiredOccurrences.isEmpty
            ? .achieved
            : (requiredOccurrences.allSatisfy { $0.status == .completed } ? .achieved : .incomplete)

        let percentage = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        let level = Self.level(forCompletionPercentage: percentage)

        return DailyComplianceSummary(status: status, level: level, completedCount: completedCount, totalCount: totalCount)
    }

    private static func level(forCompletionPercentage percentage: Double) -> DayComplianceLevel {
        switch percentage {
        case ..<0.0001: return .none
        case ..<(1.0 / 3.0): return .low
        case ..<(2.0 / 3.0): return .medium
        case ..<1.0: return .high
        default: return .perfect
        }
    }
}
