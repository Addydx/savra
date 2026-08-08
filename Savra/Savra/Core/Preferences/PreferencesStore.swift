import Foundation

protocol PreferencesStore: Sendable {
    func load() -> AppPreferences
    func save(_ preferences: AppPreferences)
}
