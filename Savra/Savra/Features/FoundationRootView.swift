import SwiftUI

struct FoundationRootView: View {
    let container: AppContainer

    var body: some View {
        Text("Savra")
            .font(.title)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    FoundationRootView(container: .foundation)
}
