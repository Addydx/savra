import FirebaseCore
import Foundation

enum FirebaseBootstrap {
    static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    static func configureIfNeeded() {
        guard !isConfigured else {
            return
        }

        FirebaseApp.configure()
    }
}
