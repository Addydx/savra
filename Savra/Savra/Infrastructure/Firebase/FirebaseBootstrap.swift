import FirebaseCore
import Foundation

enum FirebaseBootstrap {
    static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    static func configureIfNeeded() {
        guard !isConfigured else { return }

        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            return
        }

        FirebaseApp.configure(options: options)
    }
}
