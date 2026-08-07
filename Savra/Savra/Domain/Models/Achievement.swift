import Foundation

enum AchievementCondition: Equatable, Sendable {
    case loggingStreak(days: Int)
    case planAdherenceStreak(days: Int)
    case perfectWeek
    case totalMealsLogged(count: Int)
}

struct Achievement: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    /// SF Symbol name.
    let icon: String
    let condition: AchievementCondition
}

extension Achievement {
    static let all: [Achievement] = [
        Achievement(id: "logging_streak_3", title: "Primeros pasos", description: "Registra comidas 3 días seguidos", icon: "flame", condition: .loggingStreak(days: 3)),
        Achievement(id: "logging_streak_7", title: "Una semana", description: "Registra comidas 7 días seguidos", icon: "flame.fill", condition: .loggingStreak(days: 7)),
        Achievement(id: "logging_streak_14", title: "Dos semanas", description: "Registra comidas 14 días seguidos", icon: "flame.fill", condition: .loggingStreak(days: 14)),
        Achievement(id: "logging_streak_30", title: "Un mes completo", description: "Registra comidas 30 días seguidos", icon: "flame.fill", condition: .loggingStreak(days: 30)),
        Achievement(id: "logging_streak_100", title: "Imparable", description: "Registra comidas 100 días seguidos", icon: "flame.fill", condition: .loggingStreak(days: 100)),
        Achievement(id: "plan_adherence_streak_3", title: "En plan", description: "Cumple tu plan 3 días seguidos", icon: "checkmark.seal", condition: .planAdherenceStreak(days: 3)),
        Achievement(id: "plan_adherence_streak_7", title: "Disciplina semanal", description: "Cumple tu plan 7 días seguidos", icon: "checkmark.seal.fill", condition: .planAdherenceStreak(days: 7)),
        Achievement(id: "plan_adherence_streak_14", title: "Constancia real", description: "Cumple tu plan 14 días seguidos", icon: "checkmark.seal.fill", condition: .planAdherenceStreak(days: 14)),
        Achievement(id: "plan_adherence_streak_30", title: "Hábito formado", description: "Cumple tu plan 30 días seguidos", icon: "checkmark.seal.fill", condition: .planAdherenceStreak(days: 30)),
        Achievement(id: "perfect_week", title: "Semana perfecta", description: "Completa 7 de 7 días de tu plan en una semana", icon: "star.fill", condition: .perfectWeek),
        Achievement(id: "total_meals_50", title: "Medio centenar", description: "Registra 50 comidas en total", icon: "fork.knife.circle.fill", condition: .totalMealsLogged(count: 50))
    ]
}
