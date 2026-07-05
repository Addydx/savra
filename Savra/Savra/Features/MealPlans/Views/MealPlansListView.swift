import SwiftUI

struct MealPlansListView: View {
    let container: AppViewModel
    @State private var viewModel: MealPlansViewModel?
    @State private var showForm = false
    @State private var editingPlan: MealPlan?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    listContent(vm: vm)
                } else {
                    Color.clear
                        .onAppear {
                            let vm = MealPlansViewModel(container: container.container, userId: container.userId)
                            viewModel = vm
                            Task { await vm.loadPlans() }
                        }
                }
            }
            .navigationTitle("Planes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingPlan) { plan in
                if let vm = viewModel {
                    MealPlanFormView(
                        viewModel: vm,
                        editPlan: plan
                    )
                }
            }
            .sheet(isPresented: $showForm) {
                if let vm = viewModel {
                    MealPlanFormView(viewModel: vm, editPlan: nil)
                }
            }
        }
    }

    @ViewBuilder
    private func listContent(vm: MealPlansViewModel) -> some View {
        if vm.isLoading {
            ProgressView()
        } else if vm.plans.isEmpty {
            emptyState(vm: vm)
        } else {
            List {
                ForEach(vm.plans) { plan in
                    MealPlanRow(plan: plan, vm: vm, onEdit: { editingPlan = $0 })
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let plan = vm.plans[index]
                        Task { await vm.deletePlan(plan) }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func emptyState(vm: MealPlansViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No tienes planes de comida")
                .font(.headline)
            Text("Crea tu primer plan para organizar tus comidas")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showForm = true }) {
                Text("Crear plan")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(32)
    }
}

struct MealPlanRow: View {
    let plan: MealPlan
    let vm: MealPlansViewModel
    let onEdit: (MealPlan) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(plan.emoji ?? "🍽️")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.body.weight(.medium))
                    .strikethrough(!plan.isActive)
                    .foregroundColor(plan.isActive ? .primary : .secondary)
                if let time = plan.time {
                    Text(String(format: "%02d:%02d", time.hour, time.minute))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(recurrenceLabel(plan.recurrenceRule))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !plan.isActive {
                Text("Pausado")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button(action: { Task { await vm.toggleActive(plan) } }) {
                Image(systemName: plan.isActive ? "pause.circle" : "play.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onEdit(plan) }
    }

    private func recurrenceLabel(_ rule: RecurrenceRule) -> String {
        switch rule.kind {
        case .once: return "Una vez"
        case .daily: return "Todos los días"
        case .specificDays:
            guard let days = rule.daysOfWeek else { return "Días específicos" }
            let names: [String] = days.sorted(by: { $0.rawValue < $1.rawValue }).map { day in
                switch day {
                case .monday: return "L"
                case .tuesday: return "M"
                case .wednesday: return "M"
                case .thursday: return "J"
                case .friday: return "V"
                case .saturday: return "S"
                case .sunday: return "D"
                }
            }
            return names.joined(separator: " ")
        }
    }
}
