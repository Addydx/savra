import Foundation

enum OccurrenceGenerator {
    static func occurrences(for date: Date, from plans: [MealPlan], userId: UUID) -> [MealOccurrence] {
        plans.compactMap { plan in
            guard plan.isActive else { return nil }
            guard plan.recurrenceRule.startDate <= date else { return nil }
            if let endDate = plan.recurrenceRule.endDate, date > endDate { return nil }

            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)

            switch plan.recurrenceRule.kind {
            case .once:
                guard calendar.isDate(plan.recurrenceRule.startDate, inSameDayAs: date) else { return nil }
            case .daily:
                break
            case .specificDays:
                guard let days = plan.recurrenceRule.daysOfWeek,
                      days.contains(where: { $0.rawValue == weekday }) else { return nil }
            }

            return MealOccurrence(
                id: UUID(),
                mealPlanId: plan.id,
                scheduledDate: date,
                scheduledTime: plan.time,
                isRequired: true,
                status: .scheduled,
                completedAt: nil
            )
        }
    }
}
