import SwiftUI

struct AchievementCelebrationView: View {
    let achievements: [Achievement]
    let onDismiss: () -> Void

    @State private var badgeScale: CGFloat = 0.6
    @State private var confettiAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    ConfettiView(animate: confettiAnimating)

                    VStack(spacing: 16) {
                        Text(achievements.count > 1 ? "¡Nuevos logros!" : "¡Nuevo logro!")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ForEach(achievements) { achievement in
                            VStack(spacing: 6) {
                                Image(systemName: achievement.icon)
                                    .font(.system(size: 44))
                                    .foregroundColor(.accentColor)
                                    .scaleEffect(badgeScale)
                                Text(achievement.title)
                                    .font(.title3.bold())
                                    .multilineTextAlignment(.center)
                                Text(achievement.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(24)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 32)

                Button("Genial") {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }
            confettiAnimating = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    let xOffset: CGFloat
    let size: CGFloat
    let delay: Double
}

private struct ConfettiView: View {
    let animate: Bool

    private let pieces: [ConfettiPiece] = (0..<18).map { _ in
        ConfettiPiece(
            symbol: ["sparkle", "star.fill", "circle.fill"].randomElement()!,
            color: [Color.accentColor, .yellow, .orange, .pink, .green].randomElement()!,
            xOffset: CGFloat.random(in: -130...130),
            size: CGFloat.random(in: 10...18),
            delay: Double.random(in: 0...0.35)
        )
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Image(systemName: piece.symbol)
                    .font(.system(size: piece.size))
                    .foregroundColor(piece.color)
                    .offset(x: piece.xOffset, y: animate ? 220 : -30)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: 1.1).delay(piece.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
    }
}
