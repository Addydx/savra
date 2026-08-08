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

    init(container: AppContainer, userId: String, initialDisplayName: String) {
        self.container = container
        self.userId = userId
        self.displayName = initialDisplayName
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
}
