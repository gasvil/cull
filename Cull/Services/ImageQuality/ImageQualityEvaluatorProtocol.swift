import Foundation

/// Contrato para evaluar la calidad visual de forma asíncrona y segura (FR-2, FR-3, FR-4).
public protocol ImageQualityEvaluatorProtocol: Sendable {
    func evaluateQuality(for imageData: Data) async throws -> QualityAssessment
}
