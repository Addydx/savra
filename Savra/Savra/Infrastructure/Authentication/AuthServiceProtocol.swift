import Foundation

struct AuthenticatedSession: Equatable, Sendable {
    let userId: UUID
    let email: String
    let isEmailVerified: Bool
}

protocol AuthServiceProtocol: Sendable {
    var currentSession: AuthenticatedSession? { get async }
    var currentUserName: String? { get }

    func signUp(email: String, password: String, name: String) async throws -> AuthenticatedSession
    func signIn(email: String, password: String) async throws -> AuthenticatedSession
    func signOut() async throws
    func sendEmailVerification() async throws
    func reloadUser() async throws -> AuthenticatedSession
    func resetPassword(email: String) async throws
    func updateDisplayName(_ name: String) async throws
}
