import SwiftUI

struct MealLogReviewView: View {
    let viewModel: MealLoggingViewModel
    let dismiss: DismissAction

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let data = viewModel.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 16) {
                    DatePicker(
                        "¿Cuándo comiste?",
                        selection: Binding(
                            get: { viewModel.eatenAt },
                            set: { viewModel.eatenAt = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)

                    if let plan = viewModel.selectedPlan {
                        detailRow(label: "Plan", value: "\(plan.emoji ?? "") \(plan.name)")
                    } else {
                        detailRow(label: "Plan", value: "Comida libre")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alimentos")
                        .font(.headline)

                    if viewModel.selectedFoods.isEmpty {
                        Text("Sin alimentos registrados")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.selectedFoods) { food in
                            foodQuantityRow(food)
                            if food.id != viewModel.selectedFoods.last?.id {
                                Divider()
                            }
                        }
                    }

                    Button(action: { viewModel.goBackToFoodSearch() }) {
                        Text("Editar alimentos")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notas (opcional)")
                        .font(.headline)
                    TextEditor(text: Binding(
                        get: { viewModel.notes },
                        set: { viewModel.notes = $0 }
                    ))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: { Task { await viewModel.saveMealLog() } }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Guardar comida")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .disabled(viewModel.isLoading)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .navigationTitle("Revisar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.body)
        }
    }

    private func foodQuantityRow(_ food: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.name)
                    .font(.body)
                Spacer()
                if let cat = food.category {
                    Text(cat)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Stepper(
                    value: Binding(
                        get: { viewModel.quantity(for: food) },
                        set: { viewModel.setQuantity($0, for: food) }
                    ),
                    in: 0...999,
                    step: 0.5
                ) {
                    Text(quantityLabel(viewModel.quantity(for: food)))
                        .font(.subheadline.monospacedDigit())
                }

                Menu {
                    ForEach(MealLoggingViewModel.unitOptions, id: \.self) { unit in
                        Button(unit) { viewModel.setUnit(unit, for: food) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.unit(for: food))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func quantityLabel(_ value: Double) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "Cantidad: \(formatted)"
    }
}
