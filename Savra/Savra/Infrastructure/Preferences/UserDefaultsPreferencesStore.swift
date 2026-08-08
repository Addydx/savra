import Foundation

final class UserDefaultsPreferencesStore: PreferencesStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let themeKey = "preferences_theme"
    private let unitKey = "preferences_preferred_unit"
    private let notificationsKey = "preferences_default_notifications_enabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppPreferences {
        let theme = defaults.string(forKey: themeKey).flatMap(AppPreferences.Theme.init(rawValue:)) ?? .system
        let unit = defaults.string(forKey: unitKey) ?? AppPreferences.default.preferredUnit
        let notificationsEnabled = defaults.bool(forKey: notificationsKey)
        return AppPreferences(theme: theme, preferredUnit: unit, defaultNotificationsEnabled: notificationsEnabled)
    }

    func save(_ preferences: AppPreferences) {
        defaults.set(preferences.theme.rawValue, forKey: themeKey)
        defaults.set(preferences.preferredUnit, forKey: unitKey)
        defaults.set(preferences.defaultNotificationsEnabled, forKey: notificationsKey)
    }
}
