import SwiftUI

struct CreateAccountView: View {
    let container: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showVerification = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nombre")
                            .font(.subheadline.weight(.medium))
                        TextField("Tu nombre", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Correo electrónico")
                            .font(.subheadline.weight(.medium))
                        TextField("correo@ejemplo.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contraseña")
                            .font(.subheadline.weight(.medium))
                        SecureField("Mínimo 6 caracteres", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirmar contraseña")
                            .font(.subheadline.weight(.medium))
                        SecureField("Repite la contraseña", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: createAccount) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Crear cuenta")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .disabled(!isValid || isLoading)
                    .background(isValid ? Color.accentColor : Color(.systemGray4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(24)
            }
            .navigationTitle("Crear cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showVerification) {
                EmailVerificationView(container: container)
            }
        }
    }

    private func createAccount() {
        guard isValid else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await container.container.authService.signUp(email: email, password: password, name: name)
                container.userEmail = email
                container.userDisplayName = name
                isLoading = false
                dismiss()
                container.authState = .needsEmailVerification
            } catch let error as AuthError {
                errorMessage = error.errorDescription
                isLoading = false
            } catch {
                errorMessage = AuthError.from(error).errorDescription
                isLoading = false
            }
        }
    }
}
