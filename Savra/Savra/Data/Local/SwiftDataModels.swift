import Foundation
import SwiftData

@Model
final class SDMealPlan {
    @Attribute(.unique) var id: UUID
    var userId: String
    var name: String
    var emoji: String?
    var scheduleKind: String
    var timeHour: Int?
    var timeMinute: Int?
    var recurrenceKind: String
    var recurrenceDaysOfWeek: [Int]?
    var recurrenceStartDate: Date
    var recurrenceEndDate: Date?
    var notificationsEnabled: Bool
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, userId: String, name: String, emoji: String? = nil, scheduleKind: String = "routine", timeHour: Int? = nil, timeMinute: Int? = nil, recurrenceKind: String = "daily", recurrenceDaysOfWeek: [Int]? = nil, recurrenceStartDate: Date = .now, recurrenceEndDate: Date? = nil, notificationsEnabled: Bool = false, isActive: Bool = true, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.userId = userId
        self.name = name
        self.emoji = emoji
        self.scheduleKind = scheduleKind
        self.timeHour = timeHour
        self.timeMinute = timeMinute
        self.recurrenceKind = recurrenceKind
        self.recurrenceDaysOfWeek = recurrenceDaysOfWeek
        self.recurrenceStartDate = recurrenceStartDate
        self.recurrenceEndDate = recurrenceEndDate
        self.notificationsEnabled = notificationsEnabled
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension SDMealPlan {
    func toDomain() -> MealPlan {
        let scheduleKindEnum: MealPlan.ScheduleKind
        switch scheduleKind {
        case "routine": scheduleKindEnum = .routine
        case "oneTimeGoal": scheduleKindEnum = .oneTimeGoal
        case "scheduledMeal": scheduleKindEnum = .scheduledMeal
        default: scheduleKindEnum = .routine
        }

        let recurrenceKindEnum: RecurrenceRule.Kind
        switch recurrenceKind {
        case "once": recurrenceKindEnum = .once
        case "daily": recurrenceKindEnum = .daily
        case "specificDays": recurrenceKindEnum = .specificDays
        default: recurrenceKindEnum = .daily
        }

        var daysOfWeek: Set<Weekday>?
        if let vals = recurrenceDaysOfWeek {
            daysOfWeek = Set(vals.compactMap { Weekday(rawValue: $0) })
        }

        let time: MealTime?
        if let h = timeHour, let m = timeMinute {
            time = MealTime(hour: h, minute: m)
        } else {
            time = nil
        }

        let rule = RecurrenceRule(
            kind: recurrenceKindEnum,
            daysOfWeek: daysOfWeek,
            startDate: recurrenceStartDate,
            endDate: recurrenceEndDate
        )

        return MealPlan(
            id: id,
            userId: UUID(uuidString: userId) ?? UUID(),
            name: name,
            emoji: emoji,
            scheduleKind: scheduleKindEnum,
            time: time,
            recurrenceRule: rule,
            notificationsEnabled: notificationsEnabled,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func fromDomain(_ plan: MealPlan, userId: String) -> SDMealPlan {
        let sk: String
        switch plan.scheduleKind {
        case .routine: sk = "routine"
        case .oneTimeGoal: sk = "oneTimeGoal"
        case .scheduledMeal: sk = "scheduledMeal"
        }

        let rk: String
        var days: [Int]?
        switch plan.recurrenceRule.kind {
        case .once: rk = "once"
        case .daily: rk = "daily"
        case .specificDays:
            rk = "specificDays"
            days = plan.recurrenceRule.daysOfWeek?.map(\.rawValue).sorted()
        }

        return SDMealPlan(
            id: plan.id,
            userId: userId,
            name: plan.name,
            emoji: plan.emoji,
            scheduleKind: sk,
            timeHour: plan.time?.hour,
            timeMinute: plan.time?.minute,
            recurrenceKind: rk,
            recurrenceDaysOfWeek: days,
            recurrenceStartDate: plan.recurrenceRule.startDate,
            recurrenceEndDate: plan.recurrenceRule.endDate,
            notificationsEnabled: plan.notificationsEnabled,
            isActive: plan.isActive,
            createdAt: plan.createdAt,
            updatedAt: plan.updatedAt
        )
    }
}

@Model
final class SDMealOccurrence {
    @Attribute(.unique) var id: UUID
    var mealPlanId: UUID
    var userId: String
    var scheduledDate: Date
    var timeHour: Int?
    var timeMinute: Int?
    var isRequired: Bool
    var status: String
    var completedAt: Date?

    init(id: UUID, mealPlanId: UUID, userId: String, scheduledDate: Date, timeHour: Int? = nil, timeMinute: Int? = nil, isRequired: Bool = true, status: String = "scheduled", completedAt: Date? = nil) {
        self.id = id
        self.mealPlanId = mealPlanId
        self.userId = userId
        self.scheduledDate = scheduledDate
        self.timeHour = timeHour
        self.timeMinute = timeMinute
        self.isRequired = isRequired
        self.status = status
        self.completedAt = completedAt
    }
}

extension SDMealOccurrence {
    func toDomain() -> MealOccurrence {
        let statusEnum: MealOccurrence.Status
        switch status {
        case "completed": statusEnum = .completed
        case "skipped": statusEnum = .skipped
        case "missed": statusEnum = .missed
        default: statusEnum = .scheduled
        }

        let time: MealTime?
        if let h = timeHour, let m = timeMinute {
            time = MealTime(hour: h, minute: m)
        } else {
            time = nil
        }

        return MealOccurrence(
            id: id,
            mealPlanId: mealPlanId,
            scheduledDate: scheduledDate,
            scheduledTime: time,
            isRequired: isRequired,
            status: statusEnum,
            completedAt: completedAt
        )
    }

    static func fromDomain(_ occ: MealOccurrence, userId: String) -> SDMealOccurrence {
        let s: String
        switch occ.status {
        case .completed: s = "completed"
        case .skipped: s = "skipped"
        case .missed: s = "missed"
        case .scheduled: s = "scheduled"
        }

        return SDMealOccurrence(
            id: occ.id,
            mealPlanId: occ.mealPlanId,
            userId: userId,
            scheduledDate: occ.scheduledDate,
            timeHour: occ.scheduledTime?.hour,
            timeMinute: occ.scheduledTime?.minute,
            isRequired: occ.isRequired,
            status: s,
            completedAt: occ.completedAt
        )
    }
}

@Model
final class SDMealLog {
    @Attribute(.unique) var id: UUID
    var userId: String
    var mealOccurrenceId: UUID?
    var eatenAt: Date
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var items: [SDMealLogItem]
    @Relationship(deleteRule: .cascade) var photo: SDMealLogPhoto?

    init(id: UUID, userId: String, mealOccurrenceId: UUID? = nil, eatenAt: Date, notes: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, items: [SDMealLogItem] = [], photo: SDMealLogPhoto? = nil) {
        self.id = id
        self.userId = userId
        self.mealOccurrenceId = mealOccurrenceId
        self.eatenAt = eatenAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
        self.photo = photo
    }
}

extension SDMealLog {
    func toDomain() -> (MealLog, [MealLogItem], MealPhoto?) {
        let log = MealLog(
            id: id,
            userId: UUID(uuidString: userId) ?? UUID(),
            mealOccurrenceId: mealOccurrenceId,
            eatenAt: eatenAt,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let logItems = items.map { $0.toDomain() }
        let photoDomain = photo?.toDomain()
        return (log, logItems, photoDomain)
    }
}

@Model
final class SDMealLogItem {
    @Attribute(.unique) var id: UUID
    var foodItemId: UUID
    var displayName: String
    var quantity: Double?
    var unit: String?

    init(id: UUID = UUID(), foodItemId: UUID, displayName: String, quantity: Double? = nil, unit: String? = nil) {
        self.id = id
        self.foodItemId = foodItemId
        self.displayName = displayName
        self.quantity = quantity
        self.unit = unit
    }
}

extension SDMealLogItem {
    func toDomain() -> MealLogItem {
        MealLogItem(
            id: id,
            mealLogId: UUID(),
            foodItemId: foodItemId,
            displayName: displayName,
            quantity: quantity,
            unit: unit
        )
    }
}

@Model
final class SDMealLogPhoto {
    @Attribute(.unique) var id: UUID
    var localPath: String
    var thumbnailPath: String

    init(id: UUID = UUID(), localPath: String, thumbnailPath: String) {
        self.id = id
        self.localPath = localPath
        self.thumbnailPath = thumbnailPath
    }
}

extension SDMealLogPhoto {
    func toDomain() -> MealPhoto {
        MealPhoto(
            id: id,
            mealLogId: UUID(),
            localPath: localPath,
            remoteURL: nil,
            thumbnailPath: thumbnailPath
        )
    }
}

@Model
final class SDUnlockedAchievement {
    @Attribute(.unique) var id: UUID
    var userId: String
    var achievementId: String
    var unlockedAt: Date

    init(id: UUID = UUID(), userId: String, achievementId: String, unlockedAt: Date = .now) {
        self.id = id
        self.userId = userId
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
    }
}

extension SDUnlockedAchievement {
    func toDomain() -> UnlockedAchievement {
        UnlockedAchievement(
            id: id,
            userId: UUID(uuidString: userId) ?? UUID(),
            achievementId: achievementId,
            unlockedAt: unlockedAt
        )
    }
}

@Model
final class SDFoodItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String?
    var source: String
    var ownerUserId: String?

    init(id: UUID = UUID(), name: String, category: String? = nil, source: String = "local", ownerUserId: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.source = source
        self.ownerUserId = ownerUserId
    }
}

extension SDFoodItem {
    func toDomain() -> FoodItem {
        let s: FoodItem.Source
        switch source {
        case "remote": s = .remote
        case "userCreated": s = .userCreated
        default: s = .local
        }
        return FoodItem(
            id: id,
            name: name,
            category: category,
            source: s,
            ownerUserId: ownerUserId.flatMap { UUID(uuidString: $0) }
        )
    }

    static func fromDomain(_ item: FoodItem) -> SDFoodItem {
        let s: String
        switch item.source {
        case .local: s = "local"
        case .remote: s = "remote"
        case .userCreated: s = "userCreated"
        }
        return SDFoodItem(
            id: item.id,
            name: item.name,
            category: item.category,
            source: s,
            ownerUserId: item.ownerUserId?.uuidString
        )
    }
}
