import SwiftUI

struct ComplianceCalendarView: View {
    let complianceDays: [Date: DayComplianceStatus]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayHeaders = ["D", "L", "M", "M", "J", "V", "S"]

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: todayStart)
        let startOffset = (weekday - 1 + 7) % 7
        let allDays = (-startOffset..<0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: todayStart)
        } + [todayStart]
        return Array(allDays.suffix(28))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.timeIntervalSinceReferenceDate) { date in
                    let status = complianceDays[Calendar.current.startOfDay(for: date)] ?? .neutral
                    VStack(spacing: 2) {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(colorForStatus(status))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(status != .neutral ? Color(.systemGray6) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private func colorForStatus(_ status: DayComplianceStatus) -> Color {
        switch status {
        case .achieved: return .green
        case .incomplete: return .orange
        case .neutral: return .clear
        }
    }
}
