import Foundation

/// Implementación del servicio de agrupación para ráfagas nativas y tomas manuales en ráfaga rápida.
public final class BurstClusteringService: BurstClusteringServiceProtocol, @unchecked Sendable {

    public init() {}

    public func clusterize(
        candidates: [PhotoCandidate],
        timeThresholdSeconds: TimeInterval
    ) -> [BurstCluster] {
        guard !candidates.isEmpty else { return [] }

        // 1. Separar ráfagas nativas (con burstIdentifier) de fotos estándar
        var burstGroups: [String: [PhotoCandidate]] = [:]
        var sequentialCandidates: [PhotoCandidate] = []

        for candidate in candidates {
            if let burstId = candidate.asset.burstIdentifier, candidate.asset.representsBurst {
                burstGroups[burstId, default: []].append(candidate)
            } else {
                sequentialCandidates.append(candidate)
            }
        }

        var allCandidateGroups: [[PhotoCandidate]] = []

        // Añadir grupos nativos
        for (_, group) in burstGroups where group.count >= 2 {
            allCandidateGroups.append(group.sorted { $0.asset.creationDate < $1.asset.creationDate })
        }

        // 2. Agrupar tomas manuales consecutivas por ventana temporal móvil (<= timeThresholdSeconds)
        let sortedSequential = sequentialCandidates.sorted { $0.asset.creationDate < $1.asset.creationDate }
        var currentTemporalGroup: [PhotoCandidate] = []

        for candidate in sortedSequential {
            if let last = currentTemporalGroup.last {
                let interval = candidate.asset.creationDate.timeIntervalSince(last.asset.creationDate)
                if interval <= timeThresholdSeconds {
                    currentTemporalGroup.append(candidate)
                } else {
                    if currentTemporalGroup.count >= 2 {
                        allCandidateGroups.append(currentTemporalGroup)
                    }
                    currentTemporalGroup = [candidate]
                }
            } else {
                currentTemporalGroup.append(candidate)
            }
        }

        if currentTemporalGroup.count >= 2 {
            allCandidateGroups.append(currentTemporalGroup)
        }

        // 3. Evaluar ganadores y candidatos a descarte para cada grupo
        return allCandidateGroups.map { group in
            buildCluster(from: group)
        }
    }

    private func buildCluster(from group: [PhotoCandidate]) -> BurstCluster {
        // Encontrar keeper: mayor compositeScore. Ante empate exacto, el de creación más antigua (FR-4, FR-5)
        let sortedByQuality = group.enumerated().sorted { first, second in
            let score1 = first.element.assessment?.compositeScore ?? 0.0
            let score2 = second.element.assessment?.compositeScore ?? 0.0

            if abs(score1 - score2) > 0.0001 {
                return score1 > score2
            }
            // En caso de empate, el primer capturado cronológicamente
            if first.element.asset.creationDate != second.element.asset.creationDate {
                return first.element.asset.creationDate < second.element.asset.creationDate
            }
            return first.offset < second.offset
        }

        var keeperIds: Set<String> = []
        if let bestCandidate = sortedByQuality.first?.element {
            keeperIds.insert(bestCandidate.id)
        }

        // Determinar candidatos a descarte (excluyendo keeper y favoritas - FR-6, FR-7)
        var discardIds: Set<String> = []
        for candidate in group {
            if !keeperIds.contains(candidate.id) {
                if !candidate.asset.isFavorite {
                    discardIds.insert(candidate.id)
                }
            }
        }

        return BurstCluster(
            id: UUID(),
            items: group,
            keeperIds: keeperIds,
            discardIds: discardIds,
            status: .pending
        )
    }
}
