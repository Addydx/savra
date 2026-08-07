import SwiftUI

struct MainTabView: View {
    let container: AppViewModel

    var body: some View {
        TabView {
            DashboardView(container: container)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }

            MealPlansListView(container: container)
                .tabItem {
                    Label("Planes", systemImage: "list.clipboard.fill")
                }

            HistoryView(container: container)
                .tabItem {
                    Label("Historial", systemImage: "clock.fill")
                }

            AchievementsView(container: container)
                .tabItem {
                    Label("Logros", systemImage: "trophy.fill")
                }

            ProfileView(container: container)
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
    }
}
