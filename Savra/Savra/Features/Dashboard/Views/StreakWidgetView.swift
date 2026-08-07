import SwiftUI

struct StreakWidgetView: View {
    let streak: Streak?

    private var days: Int { streak?.currentStreak ?? 0 }
    private var isActive: Bool { days > 0 }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(isActive ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(days) día\(days == 1 ? "" : "s") seguidos")
                    .font(.headline)
                Text(isActive ? "Registrando comidas sin parar" : "Registra hoy para empezar tu racha")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(isActive ? Color.orange.opacity(0.12) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
