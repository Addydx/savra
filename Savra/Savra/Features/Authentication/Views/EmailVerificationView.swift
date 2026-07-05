import SwiftUI

struct EmailVerificationView: View {
    let container: AppViewModel
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isChecking = false
    @State private var isResending = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Verifica tu correo")
                .font(.title2.bold())

            Text("Te enviamos un correo de verificación a\n\(container.userEmail)")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            if let message = message {
                Text(message)
                    .font(.callout)
                    .foregroundColor(.green)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundColor(.red)
            }

            VStack(spacing: 16) {
                Button(action: checkVerification) {
                    if isChecking {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Ya verifiqué, comprobar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .disabled(isChecking)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button(action: resendEmail) {
                    if isResending {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Reenviar correo")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .disabled(isResending)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Cerrar sesión", role: .destructive) {
                    Task { await container.signOut() }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }

    private func checkVerification() {
        isChecking = true
        errorMessage = nil
        message = nil

        Task {
            do {
                let session = try await container.container.authService.reloadUser()
                isChecking = false
                if session.isEmailVerified {
                    container.authState = .authenticated
                } else {
                    message = "Aún no está verificado. Revisa tu bandeja de entrada."
                }
            } catch {
                errorMessage = "Error al comprobar. Intenta de nuevo."
                isChecking = false
            }
        }
    }

    private func resendEmail() {
        isResending = true
        errorMessage = nil
        message = nil

        Task {
            do {
                try await container.container.authService.sendEmailVerification()
                isResending = false
                message = "Correo reenviado. Revisa tu bandeja de entrada."
            } catch {
                errorMessage = "Error al reenviar. Intenta de nuevo."
                isResending = false
            }
        }
    }
}
