import Foundation
import SwiftUI
import PhotosUI

struct SelectedFoodQuantity: Equatable, Sendable {
    var quantity: Double
    var unit: String
}

@MainActor
@Observable
final class MealLoggingViewModel {
    let container: AppContainer
    let userId: String
    let dashboardVM: DashboardViewModel?
    let preSelectedPlan: MealPlan?
    let preSelectedOccurrence: MealOccurrence?

    static let unitOptions = ["porción", "g", "ml", "taza", "cucharada", "unidad"]
    private static let defaultUnit = "porción"

    var step: Step = .selectPlan
    var selectedPlan: MealPlan?
    var selectedOccurrence: MealOccurrence?
    var eatenAt: Date
    var notes: String = ""
    var selectedFoods: [FoodItem] = []
    var foodQuantities: [UUID: SelectedFoodQuantity] = [:]
    var photoData: Data?
    var photoItem: PhotosPickerItem?
    var isLoading = false
    var isSaved = false
    var errorMessage: String?
    var newlyUnlockedAchievements: [Achievement] = []

    enum Step: String {
        case selectPlan
        case addPhoto
        case searchFood
        case review
    }

    init(container: AppContainer, userId: String, dashboardVM: DashboardViewModel?, preSelectedOccurrence: (plan: MealPlan, occurrence: MealOccurrence)?) {
        self.container = container
        self.userId = userId
        self.dashboardVM = dashboardVM
        self.preSelectedPlan = preSelectedOccurrence?.plan
        self.preSelectedOccurrence = preSelectedOccurrence?.occurrence
        self.eatenAt = Date()

        if let occ = preSelectedOccurrence {
            selectedPlan = occ.plan
            selectedOccurrence = occ.occurrence
            if let time = occ.plan.time {
                let calendar = Calendar.current
                var comps = calendar.dateComponents([.year, .month, .day], from: Date())
                comps.hour = time.hour
                comps.minute = time.minute
                eatenAt = calendar.date(from: comps) ?? Date()
            }
            step = .addPhoto
        }
    }

    func selectPlan(_ plan: MealPlan) {
        selectedPlan = plan
        step = .addPhoto
    }

    func skipPlan() {
        selectedPlan = nil
        selectedOccurrence = nil
        step = .addPhoto
    }

    func continueWithoutPhoto() {
        step = .searchFood
    }

    func addFood(_ food: FoodItem) {
        if !selectedFoods.contains(where: { $0.id == food.id }) {
            selectedFoods.append(food)
            foodQuantities[food.id] = SelectedFoodQuantity(quantity: 1, unit: Self.defaultUnit)
        }
    }

    func removeFood(_ food: FoodItem) {
        selectedFoods.removeAll { $0.id == food.id }
        foodQuantities.removeValue(forKey: food.id)
    }

    func quantity(for food: FoodItem) -> Double {
        foodQuantities[food.id]?.quantity ?? 1
    }

    func unit(for food: FoodItem) -> String {
        foodQuantities[food.id]?.unit ?? Self.defaultUnit
    }

    func setQuantity(_ quantity: Double, for food: FoodItem) {
        var entry = foodQuantities[food.id] ?? SelectedFoodQuantity(quantity: 1, unit: Self.defaultUnit)
        entry.quantity = max(0, quantity)
        foodQuantities[food.id] = entry
    }

    func setUnit(_ unit: String, for food: FoodItem) {
        var entry = foodQuantities[food.id] ?? SelectedFoodQuantity(quantity: 1, unit: Self.defaultUnit)
        entry.unit = unit
        foodQuantities[food.id] = entry
    }

    func continueToReview() {
        step = .review
    }

    func goBackToFoodSearch() {
        step = .searchFood
    }

    func saveMealLog() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let logId = UUID()
            let userIdUUID = UUID(uuidString: userId) ?? UUID()

            var mealPhoto: MealPhoto?
            if let data = photoData {
                let prepared = try await container.imageService.prepareImageData(data, mealLogId: logId)
                mealPhoto = MealPhoto(
                    id: UUID(),
                    mealLogId: logId,
                    localPath: prepared.localPath,
                    remoteURL: nil,
                    thumbnailPath: prepared.thumbnailPath
                )
            }

            let log = MealLog(
                id: logId,
                userId: userIdUUID,
                mealOccurrenceId: selectedOccurrence?.id,
                eatenAt: eatenAt,
                notes: notes.isEmpty ? nil : notes,
                createdAt: .now,
                updatedAt: .now
            )

            let items = selectedFoods.map { food -> MealLogItem in
                let entry = foodQuantities[food.id]
                return MealLogItem(
                    id: UUID(),
                    mealLogId: logId,
                    foodItemId: food.id,
                    displayName: food.name,
                    quantity: entry?.quantity,
                    unit: entry?.unit
                )
            }

            try await container.mealLogRepository.create(log, items: items, photo: mealPhoto)

            if let plan = selectedPlan, let occ = selectedOccurrence {
                var updatedOccurrence = occ
                updatedOccurrence.status = .completed
                updatedOccurrence.completedAt = eatenAt
                let _ = try await container.mealOccurrenceRepository.upsert(
                    for: plan.id,
                    on: Calendar.current.startOfDay(for: eatenAt),
                    userId: userIdUUID,
                    status: .completed,
                    timeHour: plan.time?.hour,
                    timeMinute: plan.time?.minute
                )
            }

            isSaved = true
            await dashboardVM?.loadToday()

            // Achievement evaluation is a bonus on top of a successful save — a failure here
            // shouldn't surface as a save error or block the "saved" confirmation.
            if let unlocked = try? await container.evaluateAchievementsUseCase.evaluate(for: userIdUUID) {
                newlyUnlockedAchievements = unlocked
            }
        } catch {
            errorMessage = "Error al guardar: \(error.localizedDescription)"
        }
    }
}
