import SwiftUI

struct DashboardView: View {
    let container: AppViewModel
    @State private var viewModel: DashboardViewModel?
    @State private var heatmapVM: ComplianceHeatmapViewModel?
    @State private var streakVM: StreakViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    dashboardContent(vm: vm)
                } else {
                    Color.clear
                        .onAppear {
                            let vm = DashboardViewModel(
                                container: container.container,
                                userName: container.userDisplayName,
                                userId: container.userId
                            )
                            viewModel = vm
                            Task { await vm.loadToday() }
                        }
                }
            }
            .navigationTitle("Inicio")
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showMealLogger ?? false },
            set: { _ in if let vm = viewModel { vm.didDismissLogger() } }
        ), onDismiss: {
            Task { await streakVM?.load() }
        }) {
            if let vm = viewModel {
                MealLoggingFlowView(
                    container: container.container,
                    userId: container.userId,
                    dashboardVM: vm,
                    preSelectedOccurrence: vm.selectedOccurrence
                )
            }
        }
    }

    @ViewBuilder
    private func dashboardContent(vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(vm: vm)
                streakSection
                todaySection(vm: vm)
                complianceSection(vm: vm)
            }
            .padding()
        }
        .refreshable {
            await vm.loadToday()
            await streakVM?.load()
        }
    }

    @ViewBuilder
    private var streakSection: some View {
        if let streakVM {
            StreakWidgetView(streak: streakVM.loggingStreak)
        } else {
            Color.clear
                .frame(height: 0)
                .onAppear {
                    let vm = StreakViewModel(container: container.container, userId: container.userId)
                    streakVM = vm
                    Task { await vm.load() }
                }
        }
    }

    private func header(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hola, \(container.userDisplayName)")
                .font(.title2.bold())
            Text(hoyFormatted())
                .font(.subheadline)
                .foregroundColor(.secondary)
            if vm.totalRequiredCount > 0 {
                Text("\(vm.completedCount) de \(vm.totalRequiredCount) completadas")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 8)
            } else {
                Text("No hay comidas planeadas para hoy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func todaySection(vm: DashboardViewModel) -> some View {
        VStack(spacing: 12) {
            ForEach(vm.todayOccurrences, id: \.occurrence.id) { item in
                MealRowView(
                    plan: item.plan,
                    occurrence: item.occurrence
                ) {
                    vm.logMeal(for: item.plan, occurrence: item.occurrence)
                }
            }

            Button(action: { vm.logFreeMeal() }) {
                Label("Registrar comida", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func complianceSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Constancia")
                    .font(.headline)
                Spacer()
                Text("Último año")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let heatmapVM {
                if heatmapVM.isLoading && heatmapVM.daySummaries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ComplianceHeatmapView(
                        daySummaries: heatmapVM.daySummaries,
                        rangeDays: heatmapVM.rangeDays
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .onAppear {
                        let vm = ComplianceHeatmapViewModel(
                            container: container.container,
                            userId: container.userId
                        )
                        heatmapVM = vm
                        Task { await vm.load() }
                    }
            }
        }
    }

    private func hoyFormatted() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEEE d MMMM"
        return df.string(from: Date()).capitalized
    }
}

struct MealRowView: View {
    let plan: MealPlan
    let occurrence: MealOccurrence
    let onLog: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(plan.emoji ?? "🍽️")
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.body.weight(.medium))
                if let time = plan.time {
                    Text(String(format: "%02d:%02d", time.hour, time.minute))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            switch occurrence.status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            case .skipped:
                Text("Saltado")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .missed:
                Text("Perdido")
                    .font(.caption)
                    .foregroundColor(.red)
            case .scheduled:
                Button(action: onLog) {
                    Text("Registrar")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
