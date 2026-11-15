import Foundation

/// Contrato para agrupar fotografías en lotes de ráfaga o proximidad temporal (FR-1).
public protocol BurstClusteringServiceProtocol: Sendable {
    func clusterize(candidates: [PhotoCandidate], timeThresholdSeconds: TimeInterval) -> [BurstCluster]
    func clusterize(assets: [PhotoAsset], timeThresholdSeconds: TimeInterval) -> [BurstCluster]
}

public extension BurstClusteringServiceProtocol {
    func clusterize(candidates: [PhotoCandidate]) -> [BurstCluster] {
        clusterize(candidates: candidates, timeThresholdSeconds: 5.0)
    }

    func clusterize(assets: [PhotoAsset]) -> [BurstCluster] {
        clusterize(assets: assets, timeThresholdSeconds: 5.0)
    }

    func clusterize(assets: [PhotoAsset], timeThresholdSeconds: TimeInterval) -> [BurstCluster] {
        let candidates = assets.map { PhotoCandidate(asset: $0) }
        return clusterize(candidates: candidates, timeThresholdSeconds: timeThresholdSeconds)
    }
}
