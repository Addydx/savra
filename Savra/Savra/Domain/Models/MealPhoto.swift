import Foundation

struct MealPhoto: Identifiable, Equatable, Sendable {
    let id: UUID
    let mealLogId: UUID
    var localPath: String
    var remoteURL: URL?
    var thumbnailPath: String
}
