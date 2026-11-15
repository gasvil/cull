import Foundation
@testable import Cull

/// Fixture helper para crear instancias deterministas de `PhotoAsset`.
public enum PhotoAssetFixture {
    public static func make(
        id: String = UUID().uuidString,
        creationDate: Date = Date(),
        pixelWidth: Int = 4032,
        pixelHeight: Int = 3024,
        byteSize: Int64 = 2_500_000,
        isFavorite: Bool = false,
        burstIdentifier: String? = nil,
        representsBurst: Bool = false
    ) -> PhotoAsset {
        PhotoAsset(
            id: id,
            creationDate: creationDate,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            byteSize: byteSize,
            isFavorite: isFavorite,
            burstIdentifier: burstIdentifier,
            representsBurst: representsBurst
        )
    }
}

/// Mock para `PhotoLibraryServiceProtocol`.
public final class MockPhotoLibraryService: PhotoLibraryServiceProtocol, @unchecked Sendable {
    public var authorizationResult: Bool = true
    public var recentAssetsResult: [PhotoAsset] = []
    public var imageDataResult: Data = Data()
    public var deleteAssetsResult: Bool = true

    public private(set) var requestedAuthCount: Int = 0
    public private(set) var fetchRecentAssetsLimit: Int?
    public private(set) var fetchStartDate: Date?
    public private(set) var fetchEndDate: Date?
    public private(set) var deletedAssetIds: [String] = []

    public init() {}

    public func requestAuthorization() async -> Bool {
        requestedAuthCount += 1
        return authorizationResult
    }

    public func fetchRecentAssets(limit: Int) async throws -> [PhotoAsset] {
        fetchRecentAssetsLimit = limit
        return recentAssetsResult
    }

    public func fetchAssets(startDate: Date?, endDate: Date?, limit: Int) async throws -> [PhotoAsset] {
        fetchStartDate = startDate
        fetchEndDate = endDate
        fetchRecentAssetsLimit = limit
        return recentAssetsResult
    }

    public func fetchImageData(for assetId: String, targetSize: CGSize) async throws -> Data {
        return imageDataResult
    }

    public func deleteAssets(withIDs ids: [String]) async throws -> Bool {
        deletedAssetIds.append(contentsOf: ids)
        return deleteAssetsResult
    }
}

/// Mock para `ImageQualityEvaluatorProtocol`.
public actor MockImageQualityEvaluator: ImageQualityEvaluatorProtocol {
    public var assessmentToReturn: QualityAssessment

    public init(
        assessmentToReturn: QualityAssessment = QualityAssessment(
            sharpnessScore: 0.9,
            exposureScore: 0.8,
            compositeScore: 0.85
        )
    ) {
        self.assessmentToReturn = assessmentToReturn
    }

    public func setAssessment(_ assessment: QualityAssessment) {
        self.assessmentToReturn = assessment
    }

    public func evaluateQuality(for imageData: Data) async throws -> QualityAssessment {
        return assessmentToReturn
    }
}
