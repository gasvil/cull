import Foundation

/// Contrato para agrupar fotografías en lotes de ráfaga o proximidad temporal (FR-1).
public protocol BurstClusteringServiceProtocol: Sendable {
    func clusterize(assets: [PhotoAsset], timeThresholdSeconds: TimeInterval) -> [BurstCluster]
}
