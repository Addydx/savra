import Foundation

/// Orchestrates full account deletion per ADR-009: reauthenticate, wipe every local trace of the
/// user (meal logs/photos, occurrences, plans, achievements, profile/photo), then delete the
/// Firebase Auth account. Depends only on repository/service protocols, like
/// `EvaluateAchievementsUseCase`, so it stays free of view and Infrastructure-concrete types.
struct DeleteAccountUseCase: Sendable {
    private let mealPlanRepository: any MealPlanRepository
    private let mealOccurrenceRepository: any MealOccurrenceRepository
    private let mealLogRepository: any MealLogRepository
    private let achievementRepository: any AchievementRepository
    private let userProfileRepository: any UserProfileRepository
    private let imageService: any ImageServiceProtocol
    private let authService: any AuthServiceProtocol

    init(
        mealPlanRepository: any MealPlanRepository,
        mealOccurrenceRepository: any MealOccurrenceRepository,
        mealLogRepository: any MealLogRepository,
        achievementRepository: any AchievementRepository,
        userProfileRepository: any UserProfileRepository,
        imageService: any ImageServiceProtocol,
        authService: any AuthServiceProtocol
    ) {
        self.mealPlanRepository = mealPlanRepository
        self.mealOccurrenceRepository = mealOccurrenceRepository
        self.mealLogRepository = mealLogRepository
        self.achievementRepository = achievementRepository
        self.userProfileRepository = userProfileRepository
        self.imageService = imageService
        self.authService = authService
    }

    func execute(userId: UUID, currentPassword: String) async throws {
        try await authService.reauthenticate(password: currentPassword)

        let logs = try await mealLogRepository.fetchAll(for: userId)
        for (_, _, photo) in logs {
            if let photo {
                imageService.deleteImage(at: photo.localPath)
            }
        }
        try await mealLogRepository.deleteAll(for: userId)
        try await mealOccurrenceRepository.deleteAll(for: userId)
        try await mealPlanRepository.deleteAll(for: userId)
        try await achievementRepository.deleteAll(for: userId)

        if let profile = try await userProfileRepository.fetch(userId: userId), let photoPath = profile.photoLocalPath {
            imageService.deleteImage(at: photoPath)
        }
        try await userProfileRepository.delete(userId: userId)

        try await authService.deleteAccount()
    }
}
