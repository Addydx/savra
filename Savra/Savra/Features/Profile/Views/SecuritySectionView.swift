import SwiftUI

struct SecuritySectionView: View {
    let viewModel: ProfileViewModel

    @State private var showChangePassword = false
    @State private var currentPasswordForPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var showChangeEmail = false
    @State private var newEmail = ""
    @State private var currentPasswordForEmail = ""

    var body: some View {
        Section("Seguridad") {
            DisclosureGroup("Cambiar contraseña", isExpanded: $showChangePassword) {
                VStack(alignment: .leading, spacing: 10) {
                    SecureField("Contraseña actual", text: $currentPasswordForPassword)
                        .textContentType(.password)
                    SecureField("Nueva contraseña", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirmar nueva contraseña", text: $confirmPassword)
                        .textContentType(.newPassword)

                    Button(action: submitPasswordChange) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Actualizar contraseña")
                        }
                    }
                    .disabled(currentPasswordForPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || viewModel.isLoading)
                }
                .padding(.vertical, 4)
            }

            DisclosureGroup("Cambiar correo", isExpanded: $showChangeEmail) {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Nuevo correo", text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Contraseña actual", text: $currentPasswordForEmail)
                        .textContentType(.password)

                    Button(action: submitEmailChange) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Actualizar correo")
                        }
                    }
                    .disabled(newEmail.isEmpty || currentPasswordForEmail.isEmpty || viewModel.isLoading)
                }
                .padding(.vertical, 4)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            if let success = viewModel.successMessage {
                Text(success)
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        }
    }

    private func submitPasswordChange() {
        guard newPassword == confirmPassword else {
            viewModel.errorMessage = "Las contraseñas nuevas no coinciden"
            return
        }
        Task {
            await viewModel.changePassword(currentPassword: currentPasswordForPassword, newPassword: newPassword)
            if viewModel.errorMessage == nil {
                currentPasswordForPassword = ""
                newPassword = ""
                confirmPassword = ""
                showChangePassword = false
            }
        }
    }

    private func submitEmailChange() {
        Task {
            await viewModel.changeEmail(newEmail: newEmail, currentPassword: currentPasswordForEmail)
            if viewModel.errorMessage == nil {
                newEmail = ""
                currentPasswordForEmail = ""
                showChangeEmail = false
            }
        }
    }
}
