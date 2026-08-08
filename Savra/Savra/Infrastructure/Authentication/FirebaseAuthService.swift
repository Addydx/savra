import Foundation

#if !targetEnvironment(simulator)
import FirebaseAuth
#endif

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongCredentials
    case userNotFound
    case tooManyRequests
    case networkError
    case firebaseNotAvailable
    case unknown(String)
    case signOutFailed
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Correo electrónico no válido"
        case .weakPassword: return "La contraseña debe tener al menos 6 caracteres"
        case .emailAlreadyInUse: return "Este correo ya está registrado"
        case .wrongCredentials: return "Correo o contraseña incorrectos"
        case .userNotFound: return "No se encontró una cuenta con este correo"
        case .tooManyRequests: return "Demasiados intentos. Intenta más tarde"
        case .networkError: return "Error de conexión. Verifica tu internet"
        case .firebaseNotAvailable: return "Firebase no está disponible. Verifica la configuración."
        case .unknown(let msg): return msg
        case .signOutFailed: return "Error al cerrar sesión"
        case .sendFailed: return "Error al enviar el correo. Intenta de nuevo"
        }
    }

    static func from(_ error: Error) -> AuthError {
        #if !targetEnvironment(simulator)
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue: return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue: return .weakPassword
        case AuthErrorCode.emailAlreadyInUse.rawValue: return .emailAlreadyInUse
        case AuthErrorCode.wrongPassword.rawValue: return .wrongCredentials
        case AuthErrorCode.userNotFound.rawValue: return .userNotFound
        case AuthErrorCode.tooManyRequests.rawValue: return .tooManyRequests
        case AuthErrorCode.networkError.rawValue: return .networkError
        default: return .unknown(error.localizedDescription)
        }
        #else
        return .unknown(error.localizedDescription)
        #endif
    }
}

#if !targetEnvironment(simulator)

final class FirebaseAuthService: AuthServiceProtocol {
    private lazy var auth: Auth = Auth.auth()

    var currentSession: AuthenticatedSession? {
        get async {
            guard let user = auth.currentUser else { return nil }
            return AuthenticatedSession(
                userId: FirebaseUserMapper.uuid(from: user.uid),
                email: user.email ?? "",
                isEmailVerified: user.isEmailVerified
            )
        }
    }

    var firebaseUserId: String {
        auth.currentUser?.uid ?? ""
    }

    var firebaseEmail: String? {
        auth.currentUser?.email
    }

    var isEmailVerified: Bool {
        auth.currentUser?.isEmailVerified ?? false
    }

    var currentUserName: String? {
        auth.currentUser?.displayName
    }

    func signUp(email: String, password: String, name: String) async throws -> AuthenticatedSession {
        let result = try await auth.createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        try await result.user.sendEmailVerification()
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: result.user.uid),
            email: email,
            isEmailVerified: false
        )
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedSession {
        let result = try await auth.signIn(withEmail: email, password: password)
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: result.user.uid),
            email: email,
            isEmailVerified: result.user.isEmailVerified
        )
    }

    func signOut() async throws {
        try auth.signOut()
    }

    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else { throw AuthError.userNotFound }
        try await user.sendEmailVerification()
    }

    func reloadUser() async throws -> AuthenticatedSession {
        guard let user = auth.currentUser else { throw AuthError.userNotFound }
        try await user.reload()
        return AuthenticatedSession(
            userId: FirebaseUserMapper.uuid(from: user.uid),
            email: user.email ?? "",
            isEmailVerified: user.isEmailVerified
        )
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func updateDisplayName(_ name: String) async throws {
        guard let user = auth.currentUser else { throw AuthError.userNotFound }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }
}

#else

final class FirebaseAuthService: AuthServiceProtocol {
    var currentSession: AuthenticatedSession? { get async { nil } }
    var currentUserName: String? { nil }
    var firebaseUserId: String { "" }

    func signUp(email: String, password: String, name: String) async throws -> AuthenticatedSession {
        throw AuthError.firebaseNotAvailable
    }
    func signIn(email: String, password: String) async throws -> AuthenticatedSession {
        throw AuthError.firebaseNotAvailable
    }
    func signOut() async throws {
        throw AuthError.firebaseNotAvailable
    }
    func sendEmailVerification() async throws {
        throw AuthError.firebaseNotAvailable
    }
    func reloadUser() async throws -> AuthenticatedSession {
        throw AuthError.firebaseNotAvailable
    }
    func resetPassword(email: String) async throws {
        throw AuthError.firebaseNotAvailable
    }
    func updateDisplayName(_ name: String) async throws {
        throw AuthError.firebaseNotAvailable
    }
}

#endif
