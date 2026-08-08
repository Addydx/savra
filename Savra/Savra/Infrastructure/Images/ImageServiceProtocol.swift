import Foundation

struct PreparedMealImage: Equatable, Sendable {
    let localPath: String
    let thumbnailPath: String
}

protocol ImageServiceProtocol: Sendable {
    func prepareImageData(_ data: Data, mealLogId: MealLog.ID) async throws -> PreparedMealImage
    func prepareProfileImageData(_ data: Data, userId: User.ID) async throws -> PreparedMealImage
    func deleteImage(at path: String)
}
