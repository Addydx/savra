import SwiftUI
import SwiftData

@main
struct SavraApp: App {
    @State private var container: AppContainer?

    init() {
        FirebaseBootstrap.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            if let container = container {
                AppRootView(container: container)
                    .onAppear {
                        let context = container.persistence.context
                        FoodCatalogSeeder.seedIfNeeded(in: context)
                    }
            } else {
                ProgressView("Iniciando Savra...")
                    .task {
                        container = AppContainer()
                    }
            }
        }
    }
}
