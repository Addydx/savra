import SwiftUI

struct MealPlanFormView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: MealPlansViewModel
    let editPlan: MealPlan?

    @State private var name: String
    @State private var emoji: String
    @State private var hasTime: Bool
    @State private var hour: Int
    @State private var minute: Int
    @State private var recurrenceKind: String
    @State private var selectedDays: Set<Int>
    @State private var errorMessage: String?

    private let emojis = ["🍳", "🥗", "🌙", "🥪", "🍝", "🥣", "🍎", "☕", "🥤", "🍽️"]

    init(viewModel: MealPlansViewModel, editPlan: MealPlan?) {
        self.viewModel = viewModel
        self.editPlan = editPlan

        _name = State(initialValue: editPlan?.name ?? "")
        _emoji = State(initialValue: editPlan?.emoji ?? "🍽️")
        _hasTime = State(initialValue: editPlan?.time != nil)
        _hour = State(initialValue: editPlan?.time?.hour ?? 8)
        _minute = State(initialValue: editPlan?.time?.minute ?? 0)
        _recurrenceKind = State(initialValue: {
            switch editPlan?.recurrenceRule.kind {
            case .once: return "once"
            case .specificDays: return "specificDays"
            default: return "daily"
            }
        }() ?? "daily")
        _selectedDays = State(initialValue: {
            Set(editPlan?.recurrenceRule.daysOfWeek?.map(\.rawValue) ?? [])
        }())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    TextField("Nombre del plan", text: $name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji").font(.subheadline).foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                            ForEach(emojis, id: \.self) { e in
                                Text(e)
                                    .font(.title2)
                                    .padding(8)
                                    .background(emoji == e ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { emoji = e }
                            }
                        }
                    }
                }

                Section("Horario") {
                    Toggle("Asignar horario", isOn: $hasTime)
                    if hasTime {
                        DatePicker("Hora", selection: Binding(
                            get: { calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date() },
                            set: { date in
                                let comps = calendar.dateComponents([.hour, .minute], from: date)
                                hour = comps.hour ?? 8
                                minute = comps.minute ?? 0
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                }

                Section("Repetición") {
                    Picker("Frecuencia", selection: $recurrenceKind) {
                        Text("Todos los días").tag("daily")
                        Text("Días específicos").tag("specificDays")
                        Text("Una vez").tag("once")
                    }

                    if recurrenceKind == "specificDays" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Días de la semana").font(.subheadline).foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                ForEach(Array(zip(["D", "L", "M", "M", "J", "V", "S"], [1, 2, 3, 4, 5, 6, 7])), id: \.1) { (label, day) in
                                    Text(label)
                                        .font(.caption.weight(.medium))
                                        .frame(width: 36, height: 36)
                                        .background(selectedDays.contains(day) ? Color.accentColor : Color(.systemGray5))
                                        .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            if selectedDays.contains(day) {
                                                selectedDays.remove(day)
                                            } else {
                                                selectedDays.insert(day)
                                            }
                                        }
                                }
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.callout)
                    }
                }
            }
            .navigationTitle(editPlan != nil ? "Editar plan" : "Nuevo plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Guardar") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var calendar: Calendar { Calendar.current }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El nombre es obligatorio"
            return
        }

        if recurrenceKind == "specificDays" && selectedDays.isEmpty {
            errorMessage = "Selecciona al menos un día"
            return
        }

        let kind: RecurrenceRule.Kind
        var daysOfWeek: Set<Weekday>?
        switch recurrenceKind {
        case "once": kind = .once
        case "specificDays":
            kind = .specificDays
            daysOfWeek = Set(selectedDays.compactMap { Weekday(rawValue: $0) })
        default: kind = .daily
        }

        let time: MealTime? = hasTime ? MealTime(hour: hour, minute: minute) : nil

        let rule = RecurrenceRule(
            kind: kind,
            daysOfWeek: daysOfWeek,
            startDate: editPlan?.recurrenceRule.startDate ?? .now,
            endDate: nil
        )

        let plan = MealPlan(
            id: editPlan?.id ?? UUID(),
            userId: UUID(uuidString: viewModel.userId) ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji == "🍽️" ? nil : emoji,
            scheduleKind: .routine,
            time: time,
            recurrenceRule: rule,
            notificationsEnabled: false,
            isActive: editPlan?.isActive ?? true,
            createdAt: editPlan?.createdAt ?? .now,
            updatedAt: .now
        )

        Task {
            await viewModel.savePlan(plan)
            dismiss()
        }
    }
}
