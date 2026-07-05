import SwiftUI

struct SignInView: View {
    let container: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                        SecureField("Tu contraseña", text: $password)
                            .textContentType(.password)
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

                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Iniciar sesión")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .background(
                        (email.isEmpty || password.isEmpty || isLoading)
                        ? Color(.systemGray4)
                        : Color.accentColor
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("¿Olvidaste tu contraseña?") {
                        showForgotPassword = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                .padding(24)
            }
            .navigationTitle("Iniciar sesión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let session = try await container.container.authService.signIn(email: email, password: password)
                container.userEmail = session.email
                container.userDisplayName = container.container.authService.currentUserName ?? "Usuario"
                isLoading = false
                dismiss()

                if session.isEmailVerified {
                    container.authState = .authenticated
                } else {
                    container.authState = .needsEmailVerification
                }
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
