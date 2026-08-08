import SwiftUI

struct PreferencesSectionView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        Section("Preferencias") {
            Picker("Tema", selection: Binding(
                get: { viewModel.preferences.theme },
                set: { viewModel.updateTheme($0) }
            )) {
                Text("Sistema").tag(AppPreferences.Theme.system)
                Text("Claro").tag(AppPreferences.Theme.light)
                Text("Oscuro").tag(AppPreferences.Theme.dark)
            }

            Picker("Unidad por defecto", selection: Binding(
                get: { viewModel.preferences.preferredUnit },
                set: { viewModel.updatePreferredUnit($0) }
            )) {
                ForEach(MealLoggingViewModel.unitOptions, id: \.self) { unit in
                    Text(unit).tag(unit)
                }
            }

            Toggle("Notificaciones para planes nuevos", isOn: Binding(
                get: { viewModel.preferences.defaultNotificationsEnabled },
                set: { viewModel.updateDefaultNotificationsEnabled($0) }
            ))
        }
    }
}
