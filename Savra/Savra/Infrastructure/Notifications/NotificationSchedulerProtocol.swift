import Foundation

protocol NotificationSchedulerProtocol: Sendable {
    func schedule(for occurrence: MealOccurrence, plan: MealPlan) async throws
    func cancel(for occurrenceId: MealOccurrence.ID) async
    func rescheduleAll(for planId: MealPlan.ID) async throws
}
