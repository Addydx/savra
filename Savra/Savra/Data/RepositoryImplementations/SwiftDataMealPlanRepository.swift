import Foundation
import SwiftData

final class SwiftDataMealPlanRepository: @unchecked Sendable, MealPlanRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ plan: MealPlan) async throws {
        let sd = SDMealPlan.fromDomain(plan, userId: plan.userId.uuidString)
        context.insert(sd)
        try context.save()
    }

    func update(_ plan: MealPlan) async throws {
        let pid = plan.id
        let predicate = #Predicate<SDMealPlan> { $0.id == pid }
        let descriptor = FetchDescriptor<SDMealPlan>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { throw RepositoryError.notFound }
        existing.name = plan.name
        existing.emoji = plan.emoji
        existing.scheduleKind = {
            switch plan.scheduleKind {
            case .routine: return "routine"
            case .oneTimeGoal: return "oneTimeGoal"
            case .scheduledMeal: return "scheduledMeal"
            }
        }()
        existing.timeHour = plan.time?.hour
        existing.timeMinute = plan.time?.minute
        existing.recurrenceKind = {
            switch plan.recurrenceRule.kind {
            case .once: return "once"
            case .daily: return "daily"
            case .specificDays: return "specificDays"
            }
        }()
        existing.recurrenceDaysOfWeek = plan.recurrenceRule.daysOfWeek?.map(\.rawValue).sorted()
        existing.recurrenceStartDate = plan.recurrenceRule.startDate
        existing.recurrenceEndDate = plan.recurrenceRule.endDate
        existing.notificationsEnabled = plan.notificationsEnabled
        existing.isActive = plan.isActive
        existing.updatedAt = plan.updatedAt
        try context.save()
    }

    func delete(id: UUID) async throws {
        let pid = id
        let predicate = #Predicate<SDMealPlan> { $0.id == pid }
        let descriptor = FetchDescriptor<SDMealPlan>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { throw RepositoryError.notFound }
        context.delete(existing)
        try context.save()
    }

    func fetchActive(for userId: UUID) async throws -> [MealPlan] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealPlan> { $0.userId == uid && $0.isActive == true }
        let descriptor = FetchDescriptor<SDMealPlan>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }.sorted { a, b in
            let lTime = a.time.map { $0.hour * 60 + $0.minute } ?? 9999
            let rTime = b.time.map { $0.hour * 60 + $0.minute } ?? 9999
            return lTime < rTime
        }
    }

    func deleteAll(for userId: UUID) async throws {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealPlan> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDMealPlan>(predicate: predicate)
        for plan in try context.fetch(descriptor) {
            context.delete(plan)
        }
        try context.save()
    }

    func fetchAll(for userId: UUID) async throws -> [MealPlan] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealPlan> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDMealPlan>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }.sorted { a, b in
            if a.isActive != b.isActive { return a.isActive }
            let lTime = a.time.map { $0.hour * 60 + $0.minute } ?? 9999
            let rTime = b.time.map { $0.hour * 60 + $0.minute } ?? 9999
            return lTime < rTime
        }
    }
}
