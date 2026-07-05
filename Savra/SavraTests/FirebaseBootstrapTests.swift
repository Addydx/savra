import Testing
@testable import Savra

struct FirebaseBootstrapTests {
    @Test func firebaseConfiguresFromBundledPlist() {
        FirebaseBootstrap.configureIfNeeded()

        #expect(FirebaseBootstrap.isConfigured)
    }
}
