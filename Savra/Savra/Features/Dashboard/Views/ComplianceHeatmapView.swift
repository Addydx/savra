import SwiftUI

private struct SelectedDay: Identifiable {
    let date: Date
    var id: Date { date }
}

private struct HeatmapWeek: Identifiable {
    let id: Date
    let days: [Date?]
    let monthLabel: String?
}

struct ComplianceHeatmapView: View {
    let daySummaries: [Date: DailyComplianceSummary]
    let rangeDays: Int

    @State private var selectedDay: SelectedDay?

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }

    private var weeks: [HeatmapWeek] {
        buildWeeks()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 4) {
                        monthLabelsRow
                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(weeks) { week in
                                weekColumn(week)
                                    .id(week.id)
                            }
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(weeks.last?.id, anchor: .trailing)
                    }
                }
            }

            legend
        }
        .popover(item: $selectedDay) { day in
            tooltipContent(for: day)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    private var monthLabelsRow: some View {
        HStack(alignment: .bottom, spacing: cellSpacing) {
            ForEach(weeks) { week in
                Text(week.monthLabel ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize()
                    .frame(width: cellSize, alignment: .leading)
            }
        }
    }

    private func weekColumn(_ week: HeatmapWeek) -> some View {
        VStack(spacing: cellSpacing) {
            ForEach(Array(week.days.enumerated()), id: \.offset) { _, day in
                if let day {
                    cell(for: day)
                } else {
                    Color.clear.frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    private func cell(for day: Date) -> some View {
        let level = daySummaries[day]?.level ?? .none
        return RoundedRectangle(cornerRadius: 3)
            .fill(color(for: level))
            .frame(width: cellSize, height: cellSize)
            .accessibilityLabel(accessibilityLabel(for: day))
            .onTapGesture {
                selectedDay = SelectedDay(date: day)
            }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Menos")
                .font(.caption2)
                .foregroundColor(.secondary)
            ForEach(DayComplianceLevel.allCases, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text("Más")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func tooltipContent(for day: SelectedDay) -> some View {
        let summary = daySummaries[day.date]
        return VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatted(day.date))
                .font(.headline)
            if let summary, summary.totalCount > 0 {
                Text("\(summary.completedCount)/\(summary.totalCount) comidas completadas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Sin comidas planeadas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 180, alignment: .leading)
    }

    private func color(for level: DayComplianceLevel) -> Color {
        switch level {
        case .none: return Color(.systemGray5)
        case .low: return Color.accentColor.opacity(0.25)
        case .medium: return Color.accentColor.opacity(0.5)
        case .high: return Color.accentColor.opacity(0.75)
        case .perfect: return Color.accentColor
        }
    }

    private func accessibilityLabel(for day: Date) -> String {
        let summary = daySummaries[day]
        let dateText = dateFormatted(day)
        guard let summary, summary.totalCount > 0 else {
            return "\(dateText), sin comidas planeadas"
        }
        return "\(dateText), \(summary.completedCount) de \(summary.totalCount) comidas completadas"
    }

    private func dateFormatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateStyle = .long
        return df.string(from: date)
    }

    private func buildWeeks() -> [HeatmapWeek] {
        let calendar = calendar
        let todayStart = calendar.startOfDay(for: Date())
        guard let rangeStart = calendar.date(byAdding: .day, value: -(rangeDays - 1), to: todayStart) else {
            return []
        }

        let startWeekday = calendar.component(.weekday, from: rangeStart)
        let offsetToWeekStart = (startWeekday - calendar.firstWeekday + 7) % 7
        guard let alignedStart = calendar.date(byAdding: .day, value: -offsetToWeekStart, to: rangeStart) else {
            return []
        }

        let monthFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "es_MX")
            df.dateFormat = "MMM"
            return df
        }()

        var result: [HeatmapWeek] = []
        var weekStart = alignedStart
        var lastMonth = -1

        while weekStart <= todayStart {
            var days: [Date?] = []
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                    days.append(nil)
                    continue
                }
                days.append((day < rangeStart || day > todayStart) ? nil : day)
            }

            let month = calendar.component(.month, from: weekStart)
            var label: String?
            if month != lastMonth {
                label = monthFormatter.string(from: weekStart).capitalized
                lastMonth = month
            }

            result.append(HeatmapWeek(id: weekStart, days: days, monthLabel: label))

            guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = next
        }

        return result
    }
}
