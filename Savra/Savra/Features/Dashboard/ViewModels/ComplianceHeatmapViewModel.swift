import Foundation
import SwiftUI

@MainActor
@Observable
final class ComplianceHeatmapViewModel {
    enum Range: String, CaseIterable, Identifiable {
        case threeMonths = "3 meses"
        case sixMonths = "6 meses"
        case oneYear = "1 año"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .threeMonths: return 90
            case .sixMonths: return 182
            case .oneYear: return 365
            }
        }
    }

    var range: Range = .threeMonths {
        didSet {
            guard oldValue != range else { return }
            Task { await load() }
        }
    }
    var daySummaries: [Date: DailyComplianceSummary] = [:]
    var isLoading = false

    private let container: AppContainer
    private let userId: String
    private let calculator = DailyComplianceCalculator()

    init(container: AppContainer, userId: String) {
        self.container = container
        self.userId = userId
    }

    /// Loads the whole selected range in a single pass: one fetch for active plans,
    /// one ranged fetch for persisted occurrences, then a local per-day computation.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let rangeStart = calendar.date(byAdding: .day, value: -(range.days - 1), to: todayStart) else {
            daySummaries = [:]
            return
        }
        let userIdUUID = UUID(uuidString: userId) ?? UUID()

        do {
            let plans = try await container.mealPlanRepository.fetchActive(for: userIdUUID)
            let persisted = try await container.mealOccurrenceRepository.fetch(from: rangeStart, to: todayStart, userId: userIdUUID)
            let persistedByDay = Dictionary(grouping: persisted) { calendar.startOfDay(for: $0.scheduledDate) }

            var summaries: [Date: DailyComplianceSummary] = [:]
            var cursor = rangeStart
            while cursor <= todayStart {
                let computed = OccurrenceGenerator.occurrences(for: cursor, from: plans, userId: userIdUUID)
                let persistedForDay = persistedByDay[cursor] ?? []

                var merged: [MealOccurrence] = []
                for plan in plans {
                    if let pers = persistedForDay.first(where: { $0.mealPlanId == plan.id }) {
                        merged.append(pers)
                    } else if let comp = computed.first(where: { $0.mealPlanId == plan.id }) {
                        merged.append(comp)
                    }
                }

                summaries[cursor] = calculator.summary(for: merged)
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            daySummaries = summaries
        } catch {
            daySummaries = [:]
        }
    }
}
