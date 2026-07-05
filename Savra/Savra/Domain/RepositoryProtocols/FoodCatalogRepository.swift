import Foundation

protocol FoodCatalogRepository: Sendable {
    func search(query: String, userId: User.ID) async throws -> [FoodItem]
    func createUserFoodItem(_ foodItem: FoodItem) async throws
}
