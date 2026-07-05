import SwiftUI
import PhotosUI

struct MealLoggingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let container: AppContainer
    let userId: String
    let dashboardVM: DashboardViewModel?
    let preSelectedOccurrence: (plan: MealPlan, occurrence: MealOccurrence)?

    @State private var viewModel: MealLoggingViewModel

    init(container: AppContainer, userId: String, dashboardVM: DashboardViewModel?, preSelectedOccurrence: (plan: MealPlan, occurrence: MealOccurrence)?) {
        self.container = container
        self.userId = userId
        self.dashboardVM = dashboardVM
        self.preSelectedOccurrence = preSelectedOccurrence
        _viewModel = State(initialValue: MealLoggingViewModel(
            container: container,
            userId: userId,
            dashboardVM: dashboardVM,
            preSelectedOccurrence: preSelectedOccurrence
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSaved {
                    savedView
                } else {
                    switch viewModel.step {
                    case .selectPlan:
                        selectPlanView
                    case .addPhoto:
                        addPhotoView
                    case .searchFood:
                        FoodSearchView(viewModel: viewModel)
                    case .review:
                        MealLogReviewView(viewModel: viewModel, dismiss: dismiss)
                    }
                }
            }
            .navigationTitle(titleForStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !viewModel.isSaved {
                        Button("Cancelar") { dismiss() }
                    }
                }
            }
        }
    }

    private var titleForStep: String {
        switch viewModel.step {
        case .selectPlan: return "Registrar comida"
        case .addPhoto: return "Foto (opcional)"
        case .searchFood: return "¿Qué comiste?"
        case .review: return "Revisar"
        }
    }

    private var selectPlanView: some View {
        VStack(spacing: 16) {
            Text("¿A qué plan corresponde?")
                .font(.headline)
                .padding(.top)

            if let plan = viewModel.preSelectedPlan {
                planButton(plan)
            }

            Button(action: { viewModel.skipPlan() }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Comida libre (sin plan)")
                }
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding()
    }

    private func planButton(_ plan: MealPlan) -> some View {
        Button(action: { viewModel.selectPlan(plan) }) {
            HStack {
                Text(plan.emoji ?? "🍽️")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(plan.name)
                        .font(.body.weight(.medium))
                    if let time = plan.time {
                        Text(String(format: "%02d:%02d", time.hour, time.minute))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var addPhotoView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let data = viewModel.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Quitar foto") {
                    viewModel.photoData = nil
                    viewModel.photoItem = nil
                }
                .foregroundColor(.red)
            } else {
                PhotosPicker(
                    selection: Binding(
                        get: { viewModel.photoItem },
                        set: { newItem in
                            viewModel.photoItem = newItem
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    viewModel.photoData = data
                                }
                            }
                        }
                    ),
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        Text("Añadir fotografía")
                            .font(.headline)
                        Text("Opcional")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Spacer()

            Button(action: { viewModel.continueWithoutPhoto() }) {
                Text("Continuar sin foto")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
    }

    private var savedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
            Text("Comida guardada")
                .font(.title2.bold())
            Text("Tu registro se ha guardado correctamente.")
                .foregroundColor(.secondary)
            Spacer()
            Button("Listo") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
