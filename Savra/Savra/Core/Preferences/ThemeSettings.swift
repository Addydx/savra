import Foundation

@MainActor
@Observable
final class ThemeSettings {
    var theme: AppPreferences.Theme

    init(theme: AppPreferences.Theme) {
        self.theme = theme
    }
}
