import SwiftUI

struct FoodSearchView: View {
    @State private var viewModel: FoodSearchViewModel
    @State private var searchText = ""
    @State private var customFoodName = ""
    @State private var showAddCustom = false

    private let loggingVM: MealLoggingViewModel

    init(viewModel: MealLoggingViewModel) {
        self.loggingVM = viewModel
        _viewModel = State(initialValue: FoodSearchViewModel(container: viewModel.container))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Buscar alimento...", text: $searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        Task { await viewModel.search(query: newValue) }
                    }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            if !loggingVM.selectedFoods.isEmpty {
                selectedFoodsBar
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.results.isEmpty && !searchText.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("No encontramos \"\(searchText)\"")
                        .foregroundColor(.secondary)
                    Button(action: { showAddCustom = true }) {
                        Label("Crear \"\(searchText)\"", systemImage: "plus")
                    }
                }
                Spacer()
            } else if viewModel.results.isEmpty && searchText.isEmpty {
                categoriesView
            } else {
                List {
                    ForEach(viewModel.results) { food in
                        foodRow(food)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("¿Qué comiste?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if !loggingVM.selectedFoods.isEmpty {
                    Button("Revisar (\(loggingVM.selectedFoods.count))") {
                        loggingVM.continueToReview()
                    }
                }
            }
        }
        .alert("Añadir alimento", isPresented: $showAddCustom) {
            TextField("Nombre", text: $customFoodName)
            Button("Cancelar", role: .cancel) {}
            Button("Añadir") {
                let food = FoodItem(
                    id: UUID(),
                    name: customFoodName.isEmpty ? searchText : customFoodName,
                    category: nil,
                    source: .userCreated,
                    ownerUserId: nil
                )
                loggingVM.addFood(food)
                customFoodName = ""
                showAddCustom = false
            }
        } message: {
            Text("Escribe el nombre del alimento")
        }
    }

    private var categoriesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(categorizedFoods.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(categorizedFoods[category] ?? []) { food in
                                foodChip(food)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var categorizedFoods: [String: [FoodItem]] {
        Dictionary(grouping: viewModel.allFoods) { $0.category ?? "Otros" }
    }

    private func foodChip(_ food: FoodItem) -> some View {
        Button(action: { loggingVM.addFood(food) }) {
            HStack {
                Text(food.name)
                    .font(.subheadline)
                    .lineLimit(1)
                if loggingVM.selectedFoods.contains(where: { $0.id == food.id }) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                loggingVM.selectedFoods.contains(where: { $0.id == food.id })
                ? Color.accentColor.opacity(0.15)
                : Color(.systemGray6)
            )
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func foodRow(_ food: FoodItem) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.body)
                if let cat = food.category {
                    Text(cat)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if loggingVM.selectedFoods.contains(where: { $0.id == food.id }) {
                Button(action: { loggingVM.removeFood(food) }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            } else {
                Button(action: { loggingVM.addFood(food) }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var selectedFoodsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(loggingVM.selectedFoods) { food in
                    HStack(spacing: 4) {
                        Text(food.name)
                            .font(.caption)
                        Button(action: { loggingVM.removeFood(food) }) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

@MainActor
@Observable
final class FoodSearchViewModel {
    var results: [FoodItem] = []
    var allFoods: [FoodItem] = []
    var isLoading = false

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        Task { await loadAll() }
    }

    func loadAll() async {
        isLoading = true
        do {
            allFoods = try await container.foodCatalogRepository.search(query: "", userId: UUID())
            results = allFoods
        } catch {
            allFoods = []
            results = []
        }
        isLoading = false
    }

    func search(query: String) async {
        isLoading = true
        do {
            results = try await container.foodCatalogRepository.search(query: query, userId: UUID())
        } catch {
            results = query.isEmpty ? allFoods : []
        }
        isLoading = false
    }
}
