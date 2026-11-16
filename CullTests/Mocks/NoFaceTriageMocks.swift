import Foundation
@testable import Cull

/// Mock de `FacelessClassificationServiceProtocol` para pruebas deterministas.
public actor MockFacelessClassificationService: FacelessClassificationServiceProtocol {
    public var defaultResult: FacelessClassificationResult
    public var resultsByAssetId: [String: FacelessClassificationResult] = [:]
    public private(set) var classifyCallCount: Int = 0

    public init(
        defaultResult: FacelessClassificationResult = FacelessClassificationResult(
            hasFaces: false,
            category: .toValidate,
            textCount: 0,
            sharpnessScore: 0.8,
            luminanceScore: 0.5
        )
    ) {
        self.defaultResult = defaultResult
    }

    public func setDefaultResult(_ result: FacelessClassificationResult) {
        self.defaultResult = result
    }

    public func setResult(_ result: FacelessClassificationResult, forAssetId id: String) {
        self.resultsByAssetId[id] = result
    }

    public func classify(imageData: Data) async throws -> FacelessClassificationResult {
        classifyCallCount += 1
        // Si imageData contiene una clave identificadora codificada
        if let key = String(data: imageData, encoding: .utf8), let specific = resultsByAssetId[key] {
            return specific
        }
        return defaultResult
    }
}
