import Foundation

struct DailyComplianceSummary: Equatable, Sendable {
    let status: DayComplianceStatus
    let level: DayComplianceLevel
    let completedCount: Int
    let totalCount: Int
}
