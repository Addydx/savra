import SwiftUI

struct AchievementsView: View {
    let container: AppViewModel
    @State private var viewModel: AchievementsViewModel?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading && vm.items.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(vm.items) { item in
                                    badge(item)
                                }
                            }
                            .padding()
                        }
                        .refreshable { await vm.load() }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            let vm = AchievementsViewModel(container: container.container, userId: container.userId)
                            viewModel = vm
                            Task { await vm.load() }
                        }
                }
            }
            .navigationTitle("Logros")
        }
    }

    private func badge(_ item: AchievementsViewModel.AchievementDisplay) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(item.isUnlocked ? Color.accentColor.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 64, height: 64)
                Image(systemName: item.isUnlocked ? item.achievement.icon : "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(item.isUnlocked ? .accentColor : .secondary)
            }

            Text(item.achievement.title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 30)

            Text(statusLabel(item))
                .font(.caption2)
                .foregroundColor(item.isUnlocked ? .green : .secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.achievement.title). \(item.achievement.description). \(statusLabel(item))")
    }

    private func statusLabel(_ item: AchievementsViewModel.AchievementDisplay) -> String {
        guard !item.isUnlocked else { return "Desbloqueado" }

        switch item.achievement.condition {
        case .loggingStreak, .planAdherenceStreak:
            return "\(item.progressCurrent)/\(item.progressTarget) días"
        case .totalMealsLogged:
            return "\(item.progressCurrent)/\(item.progressTarget) comidas"
        case .perfectWeek:
            return "Bloqueado"
        }
    }
}
