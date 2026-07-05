import Foundation
import SwiftData

final class LocalFoodCatalogRepository: @unchecked Sendable, FoodCatalogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func search(query: String, userId: UUID) async throws -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            let descriptor = FetchDescriptor<SDFoodItem>(sortBy: [SortDescriptor(\.name)])
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
        let predicate = #Predicate<SDFoodItem> {
            $0.name.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<SDFoodItem>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func createUserFoodItem(_ foodItem: FoodItem) async throws {
        let sd = SDFoodItem.fromDomain(foodItem)
        context.insert(sd)
        try context.save()
    }

    func fetchAll() async throws -> [FoodItem] {
        let descriptor = FetchDescriptor<SDFoodItem>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
}
