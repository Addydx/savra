import Foundation

struct AuthenticatedSession: Equatable, Sendable {
    let userId: UUID
    let email: String
    let isEmailVerified: Bool
}

protocol AuthServiceProtocol: Sendable {
    var currentSession: AuthenticatedSession? { get async }

    func signOut() async throws
}
