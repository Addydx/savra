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
                    detailRow(label: "Fecha", value: dateFormatted(viewModel.eatenAt))
                    detailRow(label: "Hora", value: timeFormatted(viewModel.eatenAt))

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
                            .padding(.vertical, 4)
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

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
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

    private func dateFormatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateStyle = .long
        return df.string(from: date)
    }

    private func timeFormatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.timeStyle = .short
        return df.string(from: date)
    }
}
