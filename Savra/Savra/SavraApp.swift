//
//  SavraApp.swift
//  Savra
//
//  Created by Alex Mendez on 04/07/26.
//

import SwiftUI

@main
struct SavraApp: App {
    private let container = AppContainer.foundation

    init() {
        FirebaseBootstrap.configureIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            FoundationRootView(container: container)
        }
    }
}
