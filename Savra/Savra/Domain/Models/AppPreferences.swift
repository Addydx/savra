import Foundation

struct AppPreferences: Equatable, Sendable {
    enum Theme: String, CaseIterable, Sendable {
        case system
        case light
        case dark
    }

    var theme: Theme
    var preferredUnit: String
    var defaultNotificationsEnabled: Bool

    static let `default` = AppPreferences(theme: .system, preferredUnit: "porción", defaultNotificationsEnabled: false)
}
