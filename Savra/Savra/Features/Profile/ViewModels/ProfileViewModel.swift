import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var displayName: String
    var photoLocalPath: String?
    var photoThumbnailPath: String?
    var isLoading = false
    var errorMessage: String?

    let container: AppContainer
    let userId: String
    private let appViewModel: AppViewModel?

    init(container: AppContainer, userId: String, initialDisplayName: String, appViewModel: AppViewModel? = nil) {
        self.container = container
        self.userId = userId
        self.displayName = initialDisplayName
        self.appViewModel = appViewModel
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        let userIdUUID = UUID(uuidString: userId) ?? UUID()
        do {
            if let profile = try await container.userProfileRepository.fetch(userId: userIdUUID) {
                displayName = profile.displayName
                photoLocalPath = profile.photoLocalPath
                photoThumbnailPath = profile.photoThumbnailPath
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(name: String, photoData: Data?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre no puede estar vacío"
            return
        }

        let userIdUUID = UUID(uuidString: userId) ?? UUID()

        do {
            try await container.authService.updateDisplayName(trimmedName)

            var newLocalPath = photoLocalPath
            var newThumbnailPath = photoThumbnailPath
            if let photoData {
                let prepared = try await container.imageService.prepareProfileImageData(photoData, userId: userIdUUID)
                newLocalPath = prepared.localPath
                newThumbnailPath = prepared.thumbnailPath
            }

            let profile = UserProfile(
                id: UUID(),
                userId: userIdUUID,
                displayName: trimmedName,
                photoLocalPath: newLocalPath,
                photoThumbnailPath: newThumbnailPath,
                createdAt: .now,
                updatedAt: .now
            )
            try await container.userProfileRepository.upsert(profile)

            displayName = trimmedName
            photoLocalPath = newLocalPath
            photoThumbnailPath = newThumbnailPath
            appViewModel?.userDisplayName = trimmedName
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
