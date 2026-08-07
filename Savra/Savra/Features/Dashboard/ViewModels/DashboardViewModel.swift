import Foundation
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    var todayOccurrences: [(plan: MealPlan, occurrence: MealOccurrence)] = []
    var completedCount = 0
    var totalRequiredCount = 0
    var userName: String = ""
    var isLoading = true
    var showMealLogger = false
    var selectedOccurrence: (plan: MealPlan, occurrence: MealOccurrence)?

    private let container: AppContainer
    private let userId: String

    init(container: AppContainer, userName: String, userId: String) {
        self.container = container
        self.userName = userName
        self.userId = userId
    }

    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        let today = Calendar.current.startOfDay(for: Date())
        let userIdUUID = UUID(uuidString: userId) ?? UUID()

        do {
            let plans = try await container.mealPlanRepository.fetchActive(for: userIdUUID)
            let computedOccurrences = OccurrenceGenerator.occurrences(for: today, from: plans, userId: userIdUUID)
            let persistedOccurrences = try await container.mealOccurrenceRepository.fetch(on: today, userId: userIdUUID)

            var merged: [(MealPlan, MealOccurrence)] = []
            for plan in plans {
                if let computed = computedOccurrences.first(where: { $0.mealPlanId == plan.id }) {
                    if let persisted = persistedOccurrences.first(where: { $0.mealPlanId == plan.id }) {
                        merged.append((plan, persisted))
                    } else {
                        merged.append((plan, computed))
                    }
                }
            }

            merged.sort { lhs, rhs in
                let lTime = lhs.0.time.map { $0.hour * 60 + $0.minute } ?? 9999
                let rTime = rhs.0.time.map { $0.hour * 60 + $0.minute } ?? 9999
                return lTime < rTime
            }

            todayOccurrences = merged
            totalRequiredCount = merged.filter { $0.1.isRequired }.count
            completedCount = merged.filter { $0.1.isRequired && $0.1.status == .completed }.count
        } catch {
            todayOccurrences = []
        }
    }

    func logMeal(for plan: MealPlan, occurrence: MealOccurrence) {
        selectedOccurrence = (plan, occurrence)
        showMealLogger = true
    }

    func logFreeMeal() {
        selectedOccurrence = nil
        showMealLogger = true
    }

    func didDismissLogger() {
        showMealLogger = false
        selectedOccurrence = nil
    }
}
