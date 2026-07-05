import Foundation
import SwiftUI

@MainActor
@Observable
final class MealPlansViewModel {
    var plans: [MealPlan] = []
    var isLoading = true
    var showForm = false
    var editingPlan: MealPlan?

    private let container: AppContainer
    let userId: String

    init(container: AppContainer, userId: String) {
        self.container = container
        self.userId = userId
    }

    func loadPlans() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plans = try await container.mealPlanRepository.fetchAll(for: UUID(uuidString: userId) ?? UUID())
        } catch {
            plans = []
        }
    }

    func savePlan(_ plan: MealPlan) async {
        do {
            if plans.contains(where: { $0.id == plan.id }) {
                try await container.mealPlanRepository.update(plan)
            } else {
                try await container.mealPlanRepository.create(plan)
            }
            await loadPlans()
        } catch {}
    }

    func toggleActive(_ plan: MealPlan) async {
        var updated = plan
        updated.isActive.toggle()
        updated.updatedAt = .now
        do {
            try await container.mealPlanRepository.update(updated)
            await loadPlans()
        } catch {}
    }

    func deletePlan(_ plan: MealPlan) async {
        do {
            try await container.mealPlanRepository.delete(id: plan.id)
            await loadPlans()
        } catch {}
    }
}
