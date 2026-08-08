import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ProfileViewModel
    let appViewModel: AppViewModel

    @State private var currentPassword = ""
    @State private var confirmationText = ""
    @State private var isDeleting = false

    private static let confirmationPhrase = "ELIMINAR"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text("Esta acción no se puede deshacer")
                            .font(.title3.bold())
                        Text("Se eliminarán permanentemente tu cuenta, tus planes de comida, tu historial de registros, tus fotos y tus logros. No podrás recuperar esta información.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contraseña actual")
                            .font(.subheadline.weight(.medium))
                        SecureField("Tu contraseña", text: $currentPassword)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Escribe \(Self.confirmationPhrase) para confirmar")
                            .font(.subheadline.weight(.medium))
                        TextField(Self.confirmationPhrase, text: $confirmationText)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                    }

                    Button(action: confirmDelete) {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Eliminar cuenta")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .disabled(!canConfirm || isDeleting)
                    .background(canConfirm ? Color.red : Color(.systemGray4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(24)
            }
            .navigationTitle("Eliminar cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private var canConfirm: Bool {
        !currentPassword.isEmpty
            && confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == Self.confirmationPhrase
    }

    private func confirmDelete() {
        isDeleting = true
        Task {
            let success = await viewModel.deleteAccount(currentPassword: currentPassword)
            isDeleting = false
            if success {
                await appViewModel.signOut()
            }
        }
    }
}
