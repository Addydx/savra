import Foundation

protocol MealLogRepository: Sendable {
    func create(_ log: MealLog, items: [MealLogItem], photo: MealPhoto?) async throws
    func update(_ log: MealLog) async throws
    func delete(id: MealLog.ID) async throws
    func fetch(for userId: User.ID, from startDate: Date, to endDate: Date) async throws -> [MealLog]
    func fetchAll(for userId: User.ID) async throws -> [(MealLog, [MealLogItem], MealPhoto?)]
    func fetchWithDetails(for userId: User.ID, from startDate: Date, to endDate: Date) async throws -> [(MealLog, [MealLogItem], MealPhoto?)]
    func deleteAll(for userId: User.ID) async throws
}
