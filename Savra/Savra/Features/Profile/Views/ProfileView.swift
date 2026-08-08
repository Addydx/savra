import SwiftUI

struct ProfileView: View {
    let container: AppViewModel
    @State private var viewModel: ProfileViewModel?
    @State private var showSignOutAlert = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ProfileAvatarView(
                            name: viewModel?.displayName ?? container.userDisplayName,
                            photoPath: viewModel?.photoThumbnailPath,
                            size: 48
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel?.displayName ?? container.userDisplayName)
                                .font(.headline)
                            Text(container.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Editar") { showEditProfile = true }
                            .font(.subheadline)
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
            .task {
                if viewModel == nil {
                    let vm = ProfileViewModel(
                        container: container.container,
                        userId: container.userId,
                        initialDisplayName: container.userDisplayName,
                        appViewModel: container
                    )
                    viewModel = vm
                    await vm.loadProfile()
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let vm = viewModel {
                    EditProfileView(viewModel: vm)
                }
            }
        }
    }
}
