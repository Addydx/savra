import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var displayName: String
    var photoLocalPath: String?
    var photoThumbnailPath: String?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var preferences: AppPreferences

    let container: AppContainer
    let userId: String
    private let appViewModel: AppViewModel?

    init(container: AppContainer, userId: String, initialDisplayName: String, appViewModel: AppViewModel? = nil) {
        self.container = container
        self.userId = userId
        self.displayName = initialDisplayName
        self.appViewModel = appViewModel
        self.preferences = container.preferencesStore.load()
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

    func changePassword(currentPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard newPassword.count >= 6 else {
            errorMessage = AuthError.weakPassword.errorDescription
            return
        }

        do {
            try await container.authService.reauthenticate(password: currentPassword)
            try await container.authService.updatePassword(newPassword)
            successMessage = "Contraseña actualizada"
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.from(error).errorDescription
        }
    }

    func changeEmail(newEmail: String, currentPassword: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = AuthError.invalidEmail.errorDescription
            return
        }

        do {
            try await container.authService.reauthenticate(password: currentPassword)
            try await container.authService.updateEmail(trimmedEmail)
            try? await container.authService.sendEmailVerification()
            appViewModel?.userEmail = trimmedEmail
            successMessage = "Correo actualizado. Revisa tu bandeja para verificarlo."
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.from(error).errorDescription
        }
    }

    func updateTheme(_ theme: AppPreferences.Theme) {
        preferences.theme = theme
        container.preferencesStore.save(preferences)
        container.themeSettings.theme = theme
    }

    func updatePreferredUnit(_ unit: String) {
        preferences.preferredUnit = unit
        container.preferencesStore.save(preferences)
    }

    func updateDefaultNotificationsEnabled(_ enabled: Bool) {
        preferences.defaultNotificationsEnabled = enabled
        container.preferencesStore.save(preferences)
    }

    @discardableResult
    func deleteAccount(currentPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let userIdUUID = UUID(uuidString: userId) ?? UUID()
        do {
            try await container.deleteAccountUseCase.execute(userId: userIdUUID, currentPassword: currentPassword)
            return true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = AuthError.from(error).errorDescription
            return false
        }
    }
}
