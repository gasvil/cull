import Foundation

/// Resultado del análisis y clasificación semántica de una fotografía.
public struct FacelessClassificationResult: Sendable, Equatable {
    public let hasFaces: Bool
    public let category: FacelessCategory?
    public let textCount: Int
    public let sharpnessScore: Float
    public let luminanceScore: Float

    public init(
        hasFaces: Bool,
        category: FacelessCategory?,
        textCount: Int = 0,
        sharpnessScore: Float = 0.5,
        luminanceScore: Float = 0.5
    ) {
        self.hasFaces = hasFaces
        self.category = category
        self.textCount = textCount
        self.sharpnessScore = sharpnessScore
        self.luminanceScore = luminanceScore
    }
}

/// Contrato para el servicio de clasificación de fotografías sin rostros.
public protocol FacelessClassificationServiceProtocol: Sendable {
    func classify(imageData: Data) async throws -> FacelessClassificationResult
}
