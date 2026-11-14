import Foundation

/// Contrato estandarizado de errores para la aplicación Cull.
/// Diseñado para cumplir con el principio P4 (Resilience: fail with typed errors).
public enum AppError: LocalizedError, Sendable, Equatable {
    case invalidInput(reason: String)
    case resourceNotFound(identifier: String)
    case operationFailed(description: String)
    case unauthorized
    case unexpected(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let reason):
            return "Entrada no válida: \(reason)"
        case .resourceNotFound(let identifier):
            return "Recurso no encontrado: \(identifier)"
        case .operationFailed(let description):
            return "Operación fallida: \(description)"
        case .unauthorized:
            return "No autorizado para realizar esta acción."
        case .unexpected(let message):
            return "Error inesperado: \(message)"
        }
    }
}
