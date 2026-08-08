import Foundation

final class SimulatorAuthService: AuthServiceProtocol {
    private let defaults = UserDefaults.standard
    private let uidKey = "sim_auth_uid"
    private let emailKey = "sim_auth_email"
    private let nameKey = "sim_auth_name"
    private let verifiedKey = "sim_auth_verified"

    var currentSession: AuthenticatedSession? {
        get async {
            guard let uid = defaults.string(forKey: uidKey),
                  let email = defaults.string(forKey: emailKey) else {
                return nil
            }
            return AuthenticatedSession(
                userId: FirebaseUserMapper.uuid(from: uid),
                email: email,
                isEmailVerified: defaults.bool(forKey: verifiedKey)
            )
        }
    }

    var firebaseUserId: String {
        defaults.string(forKey: uidKey) ?? ""
    }

    var currentUserName: String? {
        defaults.string(forKey: nameKey) ?? "Usuario"
    }

    func signUp(email: String, password: String, name: String) async throws -> AuthenticatedSession {
        let uid = UUID().uuidString
        defaults.set(uid, forKey: uidKey)
        defaults.set(email, forKey: emailKey)
        defaults.set(name, forKey: nameKey)
        defaults.set(false, forKey: verifiedKey)
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: uid),
            email: email,
            isEmailVerified: false
        )
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedSession {
        let storedEmail = defaults.string(forKey: emailKey)
        if storedEmail == nil {
            let uid = UUID().uuidString
            defaults.set(uid, forKey: uidKey)
            defaults.set(email, forKey: emailKey)
            defaults.set("Usuario", forKey: nameKey)
            defaults.set(true, forKey: verifiedKey)
        }
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: defaults.string(forKey: uidKey) ?? ""),
            email: email,
            isEmailVerified: defaults.bool(forKey: verifiedKey)
        )
    }

    func signOut() async throws {
        defaults.removeObject(forKey: uidKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: nameKey)
    }

    func sendEmailVerification() async throws {
        defaults.set(true, forKey: verifiedKey)
    }

    func reloadUser() async throws -> AuthenticatedSession {
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: defaults.string(forKey: uidKey) ?? ""),
            email: defaults.string(forKey: emailKey) ?? "",
            isEmailVerified: defaults.bool(forKey: verifiedKey)
        )
    }

    func resetPassword(email: String) async throws {
        // no-op in simulator
    }

    func updateDisplayName(_ name: String) async throws {
        defaults.set(name, forKey: nameKey)
    }

    func reauthenticate(password: String) async throws {
        // No real password is stored in the simulator's stand-in auth; only guard against empty input.
        guard !password.isEmpty else { throw AuthError.wrongCredentials }
    }

    func updateEmail(_ newEmail: String) async throws {
        defaults.set(newEmail, forKey: emailKey)
    }

    func updatePassword(_ newPassword: String) async throws {
        // No-op: the simulator's stand-in auth doesn't store a password.
    }

    func deleteAccount() async throws {
        defaults.removeObject(forKey: uidKey)
        defaults.removeObject(forKey: emailKey)
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: verifiedKey)
    }
}
