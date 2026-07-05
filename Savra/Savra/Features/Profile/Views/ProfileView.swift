import SwiftUI

struct ProfileView: View {
    let container: AppViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(container.userDisplayName)
                                .font(.headline)
                            Text(container.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    HStack {
                        Text("Estado")
                        Spacer()
                        Label("Verificado", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                }

                Section {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive, action: { showSignOutAlert = true }) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
            .alert("Cerrar sesión", isPresented: $showSignOutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    Task { await container.signOut() }
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
        }
    }
}
