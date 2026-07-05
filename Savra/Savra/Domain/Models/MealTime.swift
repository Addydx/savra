import Foundation

struct MealTime: Equatable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0...23).contains(hour), "Hour must be in 0...23")
        precondition((0...59).contains(minute), "Minute must be in 0...59")
        self.hour = hour
        self.minute = minute
    }
}
