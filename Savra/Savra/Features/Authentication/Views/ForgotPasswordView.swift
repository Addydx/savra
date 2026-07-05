import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if sent {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    Text("Correo enviado")
                        .font(.title2.bold())
                    Text("Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Listo") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
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

                    if let error = errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                    }

                    if let msg = message {
                        Text(msg)
                            .font(.callout)
                            .foregroundColor(.green)
                    }

                    Button(action: sendReset) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("Enviar correo de recuperación")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .background(email.isEmpty ? Color(.systemGray4) : Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
            .navigationTitle("Recuperar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func sendReset() {
        isLoading = true
        errorMessage = nil
        message = nil

        Task {
            do {
                try await FirebaseAuthService().resetPassword(email: email)
                isLoading = false
                sent = true
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
