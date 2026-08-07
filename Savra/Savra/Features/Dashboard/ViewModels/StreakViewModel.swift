import Foundation
import SwiftUI

@MainActor
@Observable
final class StreakViewModel {
    var loggingStreak: Streak?
    var isLoading = false

    private let container: AppContainer
    private let userId: String

    init(container: AppContainer, userId: String) {
        self.container = container
        self.userId = userId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let userIdUUID = UUID(uuidString: userId) ?? UUID()
        do {
            let snapshot = try await container.evaluateAchievementsUseCase.currentProgress(for: userIdUUID)
            loggingStreak = snapshot.loggingStreak
        } catch {
            loggingStreak = nil
        }
    }
}
