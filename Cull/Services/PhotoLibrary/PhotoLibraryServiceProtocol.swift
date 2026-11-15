import Foundation

/// Contrato para interactuar con la biblioteca de fotos sin acoplamiento a PhotoKit.
public protocol PhotoLibraryServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func fetchRecentAssets(limit: Int) async throws -> [PhotoAsset]
    func fetchAssets(startDate: Date?, endDate: Date?, limit: Int) async throws -> [PhotoAsset]
    func fetchImageData(for assetId: String, targetSize: CGSize) async throws -> Data
    func deleteAssets(withIDs ids: [String]) async throws -> Bool
}

public extension PhotoLibraryServiceProtocol {
    func fetchRecentAssets(limit: Int) async throws -> [PhotoAsset] {
        try await fetchAssets(startDate: nil, endDate: nil, limit: limit)
    }
}
