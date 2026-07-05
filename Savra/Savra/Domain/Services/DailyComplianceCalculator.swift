import Foundation

struct DailyComplianceCalculator: Sendable {
    func status(for occurrences: [MealOccurrence]) -> DayComplianceStatus {
        guard !occurrences.isEmpty else {
            return .neutral
        }

        let requiredOccurrences = occurrences.filter(\.isRequired)
        guard !requiredOccurrences.isEmpty else {
            return .achieved
        }

        return requiredOccurrences.allSatisfy { $0.status == .completed } ? .achieved : .incomplete
    }
}
