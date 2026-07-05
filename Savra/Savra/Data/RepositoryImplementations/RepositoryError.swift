import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Elemento no encontrado"
        case .saveFailed(let msg): return "Error al guardar: \(msg)"
        }
    }
}
