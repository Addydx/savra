import SwiftUI

struct HistoryView: View {
    let container: AppViewModel
    @State private var viewModel: HistoryViewModel?
    @State private var selectedLog: (log: MealLog, items: [MealLogItem], photo: MealPhoto?)?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    listContent(vm: vm)
                } else {
                    Color.clear
                        .onAppear {
                            let vm = HistoryViewModel(container: container.container, userId: container.userId)
                            viewModel = vm
                            Task { await vm.loadHistory() }
                        }
                }
            }
            .navigationTitle("Historial")
            .refreshable { await viewModel?.loadHistory() }
            .sheet(item: Binding(
                get: { selectedLog.map { LogDetailWrapper(id: $0.log.id, log: $0.log, items: $0.items, photo: $0.photo) } },
                set: { selectedLog = $0.map { ($0.log, $0.items, $0.photo) } }
            )) { wrapper in
                LogDetailView(log: wrapper.log, items: wrapper.items, photo: wrapper.photo)
            }
        }
    }

    @ViewBuilder
    private func listContent(vm: HistoryViewModel) -> some View {
        if vm.isLoading {
            ProgressView()
        } else if vm.entries.isEmpty {
            emptyState
        } else {
            List {
                ForEach(vm.entries, id: \.log.id) { entry in
                    Button(action: { selectedLog = entry }) {
                        HistoryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No hay registros")
                .font(.headline)
            Text("Tus comidas registradas aparecerán aquí")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

struct HistoryRow: View {
    let entry: (log: MealLog, items: [MealLogItem], photo: MealPhoto?)

    var body: some View {
        HStack(spacing: 16) {
            if let photo = entry.photo {
                let image = LocalImageService().loadImage(at: photo.thumbnailPath)
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderImage
                }
            } else {
                placeholderImage
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.log.mealOccurrenceId != nil ? "Comida registrada" : "Comida libre")
                    .font(.body.weight(.medium))
                Text(entry.log.eatenAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.log.eatenAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if !entry.items.isEmpty {
                    Text(entry.items.map(\.displayName).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
    }
}

struct LogDetailWrapper: Identifiable {
    let id: UUID
    let log: MealLog
    let items: [MealLogItem]
    let photo: MealPhoto?
}

struct LogDetailView: View {
    let log: MealLog
    let items: [MealLogItem]
    let photo: MealPhoto?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let photo = photo {
                        let image = LocalImageService().loadImage(at: photo.localPath)
                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    VStack(spacing: 12) {
                        DetailRow(label: "Fecha", value: log.eatenAt.formatted(date: .long, time: .shortened))
                        DetailRow(label: "Tipo", value: log.mealOccurrenceId != nil ? "Planificado" : "Comida libre")
                        if let notes = log.notes, !notes.isEmpty {
                            DetailRow(label: "Notas", value: notes)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alimentos")
                                .font(.headline)
                            ForEach(items) { item in
                                HStack {
                                    Text(item.displayName)
                                    Spacer()
                                    if let qty = item.quantity {
                                        Text("\(qty, specifier: "%.0f") \(item.unit ?? "")")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
    }
}
