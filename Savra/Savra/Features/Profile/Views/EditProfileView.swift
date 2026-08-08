import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ProfileViewModel

    @State private var name: String
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.displayName)
    }

    var body: some View {
        let existingThumbnailPath = viewModel.photoThumbnailPath

        return NavigationStack {
            VStack(spacing: 24) {
                PhotosPicker(
                    selection: Binding(
                        get: { photoItem },
                        set: { newItem in
                            photoItem = newItem
                            guard let newItem else { return }
                            Task {
                                do {
                                    if let data = try await newItem.loadTransferable(type: Data.self) {
                                        photoData = data
                                        viewModel.errorMessage = nil
                                    } else {
                                        viewModel.errorMessage = "No se pudo cargar la foto seleccionada."
                                    }
                                } catch {
                                    viewModel.errorMessage = "No se pudo cargar la foto: \(error.localizedDescription)"
                                }
                            }
                        }
                    ),
                    matching: .images
                ) {
                    ZStack(alignment: .bottomTrailing) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            ProfileAvatarView(name: name, photoPath: existingThumbnailPath, size: 100)
                        }

                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                            .background(Color(.systemBackground), in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre")
                        .font(.subheadline.weight(.medium))
                    TextField("Tu nombre", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") { save() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            await viewModel.updateProfile(name: name, photoData: photoData)
            isSaving = false
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}
