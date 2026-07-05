import Foundation
import SwiftData

final class SwiftDataMealOccurrenceRepository: @unchecked Sendable, MealOccurrenceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ occurrence: MealOccurrence) async throws {
        let userId = occurrence.id.uuidString
        let sd = SDMealOccurrence.fromDomain(occurrence, userId: userId)
        context.insert(sd)
        try context.save()
    }

    func update(_ occurrence: MealOccurrence) async throws {
        let oid = occurrence.id
        let predicate = #Predicate<SDMealOccurrence> { $0.id == oid }
        let descriptor = FetchDescriptor<SDMealOccurrence>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { throw RepositoryError.notFound }
        existing.status = {
            switch occurrence.status {
            case .scheduled: return "scheduled"
            case .completed: return "completed"
            case .skipped: return "skipped"
            case .missed: return "missed"
            }
        }()
        existing.completedAt = occurrence.completedAt
        try context.save()
    }

    func fetch(for mealPlanId: UUID) async throws -> [MealOccurrence] {
        let mid = mealPlanId
        let predicate = #Predicate<SDMealOccurrence> { $0.mealPlanId == mid }
        let descriptor = FetchDescriptor<SDMealOccurrence>(predicate: predicate)
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(on date: Date, userId: UUID) async throws -> [MealOccurrence] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealOccurrence> {
            $0.userId == uid && $0.scheduledDate >= start && $0.scheduledDate < end
        }
        let descriptor = FetchDescriptor<SDMealOccurrence>(predicate: predicate)
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func upsert(for planId: UUID, on date: Date, userId: UUID, status: MealOccurrence.Status, timeHour: Int?, timeMinute: Int?) async throws -> MealOccurrence {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { throw RepositoryError.saveFailed("Invalid date") }
        let pid = planId
        let predicate = #Predicate<SDMealOccurrence> {
            $0.mealPlanId == pid && $0.scheduledDate >= start && $0.scheduledDate < end
        }
        let descriptor = FetchDescriptor<SDMealOccurrence>(predicate: predicate)
        let existing = try context.fetch(descriptor).first

        let statusString: String = {
            switch status {
            case .scheduled: return "scheduled"
            case .completed: return "completed"
            case .skipped: return "skipped"
            case .missed: return "missed"
            }
        }()

        if let existing {
            existing.status = statusString
            existing.completedAt = status == .completed ? date : nil
            try context.save()
            return existing.toDomain()
        } else {
            let new = SDMealOccurrence(
                id: UUID(),
                mealPlanId: planId,
                userId: userId.uuidString,
                scheduledDate: date,
                timeHour: timeHour,
                timeMinute: timeMinute,
                isRequired: true,
                status: statusString,
                completedAt: status == .completed ? date : nil
            )
            context.insert(new)
            try context.save()
            return new.toDomain()
        }
    }
}
