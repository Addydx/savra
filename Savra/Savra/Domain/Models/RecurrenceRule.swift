import Foundation

struct RecurrenceRule: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case once
        case daily
        case specificDays
    }

    let kind: Kind
    let daysOfWeek: Set<Weekday>?
    let startDate: Date
    let endDate: Date?

    init(kind: Kind, daysOfWeek: Set<Weekday>? = nil, startDate: Date, endDate: Date? = nil) {
        switch kind {
        case .specificDays:
            precondition(daysOfWeek?.isEmpty == false, "specificDays recurrence requires at least one weekday")
        case .once, .daily:
            precondition(daysOfWeek == nil, "daysOfWeek is only valid for specificDays recurrence")
        }

        if let endDate {
            precondition(endDate >= startDate, "Recurrence endDate cannot be before startDate")
        }

        self.kind = kind
        self.daysOfWeek = daysOfWeek
        self.startDate = startDate
        self.endDate = endDate
    }
}
