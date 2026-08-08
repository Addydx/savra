import Foundation
import SwiftData

final class SwiftDataMealLogRepository: @unchecked Sendable, MealLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ log: MealLog, items: [MealLogItem], photo: MealPhoto?) async throws {
        let sdItems = items.map { item in
            SDMealLogItem(id: item.id, foodItemId: item.foodItemId, displayName: item.displayName, quantity: item.quantity, unit: item.unit)
        }

        var sdPhoto: SDMealLogPhoto?
        if let p = photo {
            sdPhoto = SDMealLogPhoto(id: p.id, localPath: p.localPath, thumbnailPath: p.thumbnailPath)
        }

        let sd = SDMealLog(
            id: log.id,
            userId: log.userId.uuidString,
            mealOccurrenceId: log.mealOccurrenceId,
            eatenAt: log.eatenAt,
            notes: log.notes,
            createdAt: log.createdAt,
            updatedAt: log.updatedAt,
            items: sdItems,
            photo: sdPhoto
        )
        context.insert(sd)
        try context.save()
    }

    func update(_ log: MealLog) async throws {
        let lid = log.id
        let predicate = #Predicate<SDMealLog> { $0.id == lid }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { throw RepositoryError.notFound }
        existing.notes = log.notes
        existing.eatenAt = log.eatenAt
        existing.updatedAt = log.updatedAt
        try context.save()
    }

    func delete(id: UUID) async throws {
        let lid = id
        let predicate = #Predicate<SDMealLog> { $0.id == lid }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        guard let existing = try context.fetch(descriptor).first else { throw RepositoryError.notFound }
        context.delete(existing)
        try context.save()
    }

    func fetch(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [MealLog] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealLog> {
            $0.userId == uid && $0.eatenAt >= startDate && $0.eatenAt <= endDate
        }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        return try context.fetch(descriptor).map { $0.toDomain().0 }
    }

    func fetchAll(for userId: UUID) async throws -> [(MealLog, [MealLogItem], MealPhoto?)] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealLog> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results
            .sorted { $0.eatenAt > $1.eatenAt }
            .map { $0.toDomain() }
    }

    func fetchWithDetails(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [(MealLog, [MealLogItem], MealPhoto?)] {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealLog> {
            $0.userId == uid && $0.eatenAt >= startDate && $0.eatenAt <= endDate
        }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results
            .sorted { $0.eatenAt > $1.eatenAt }
            .map { $0.toDomain() }
    }

    func deleteAll(for userId: UUID) async throws {
        let uid = userId.uuidString
        let predicate = #Predicate<SDMealLog> { $0.userId == uid }
        let descriptor = FetchDescriptor<SDMealLog>(predicate: predicate)
        for log in try context.fetch(descriptor) {
            context.delete(log)
        }
        try context.save()
    }
}
