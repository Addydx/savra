import SwiftUI

enum AppAuthState {
    case loading
    case signedOut
    case needsEmailVerification
    case authenticated
}

@MainActor
@Observable
final class AppViewModel {
    var authState: AppAuthState = .loading
    var isLoading = true
    var userDisplayName: String = ""
    var userEmail: String = ""
    var userId: String = ""

    let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func checkAuthState() async {
        isLoading = true
        authState = .loading

        let session = await container.authService.currentSession

        if let session {
            userEmail = session.email
            userDisplayName = container.authService.currentUserName ?? "Usuario"
            userId = session.userId.uuidString
            if session.isEmailVerified {
                authState = .authenticated
            } else {
                authState = .needsEmailVerification
            }
        } else {
            authState = .signedOut
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await container.authService.signOut()
            authState = .signedOut
        } catch {
            // Sign out even if Firebase fails locally
            authState = .signedOut
        }
    }
}

struct AppRootView: View {
    @State private var viewModel: AppViewModel
    @State private var showSplash = true

    init(container: AppContainer) {
        _viewModel = State(initialValue: AppViewModel(container: container))
    }

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        Task {
                            await viewModel.checkAuthState()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else if viewModel.isLoading {
                SplashView()
            } else {
                switch viewModel.authState {
                case .loading:
                    SplashView()
                case .signedOut:
                    WelcomeView(container: viewModel)
                case .needsEmailVerification:
                    EmailVerificationView(container: viewModel)
                case .authenticated:
                    MainTabView(container: viewModel)
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)
            Text("Savra")
                .font(.largeTitle.bold())
            Text("Tus comidas, simples y organizadas")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
