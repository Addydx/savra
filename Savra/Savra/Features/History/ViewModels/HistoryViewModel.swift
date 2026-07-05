import Foundation
import SwiftUI

@MainActor
@Observable
final class HistoryViewModel {
    var entries: [(log: MealLog, items: [MealLogItem], photo: MealPhoto?)] = []
    var isLoading = true

    private let container: AppContainer
    private let userId: String

    init(container: AppContainer, userId: String) {
        self.container = container
        self.userId = userId
    }

    func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await container.mealLogRepository.fetchAll(for: UUID(uuidString: userId) ?? UUID())
        } catch {
            entries = []
        }
    }
}
