import SwiftUI
import OSLog

/// Estados posibles de la pantalla de triaje de ráfagas.
public enum BurstTriageViewState: Equatable, Sendable {
    case idle
    case requestingPermission
    case analyzing(progress: Float, message: String)
    case loaded(clusters: [BurstCluster])
    case processingDiscard
    case empty(reason: String)
    case error(AppError)
}

/// ViewModel reactivo para la pantalla de curación y triaje de ráfagas.
/// Gestiona la interacción con los servicios de biblioteca, agrupación y evaluación visual.
@Observable
@MainActor
public final class BurstTriageViewModel {
    public private(set) var state: BurstTriageViewState = .idle

    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let clusteringService: BurstClusteringServiceProtocol
    private let qualityEvaluator: ImageQualityEvaluatorProtocol
    private let logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "BurstTriageViewModel")

    public init(
        photoLibraryService: PhotoLibraryServiceProtocol,
        clusteringService: BurstClusteringServiceProtocol,
        qualityEvaluator: ImageQualityEvaluatorProtocol
    ) {
        self.photoLibraryService = photoLibraryService
        self.clusteringService = clusteringService
        self.qualityEvaluator = qualityEvaluator
    }

    /// Espacio acumulado total recuperable entre todos los lotes analizados (FR-8).
    public var totalRecoverableByteSize: Int64 {
        if case .loaded(let clusters) = state {
            return clusters.reduce(0) { $0 + $1.recoverableByteSize }
        }
        return 0
    }

    /// Carga las fotos recientes, agrupa candidatos por ráfaga/ventana temporal y evalúa su calidad.
    public func loadAndAnalyzeClusters() async {
        state = .requestingPermission

        let isAuthorized = await photoLibraryService.requestAuthorization()
        guard isAuthorized else {
            state = .error(.unauthorized)
            return
        }

        state = .analyzing(progress: 0.1, message: "Buscando fotos recientes...")

        do {
            let assets = try await photoLibraryService.fetchRecentAssets(limit: 200)
            guard !assets.isEmpty else {
                state = .empty(reason: "No se encontraron fotos en la biblioteca.")
                return
            }

            state = .analyzing(progress: 0.3, message: "Agrupando ráfagas y fotos similares...")
            let rawClusters = clusteringService.clusterize(assets: assets, timeThresholdSeconds: 5.0)

            guard !rawClusters.isEmpty else {
                state = .empty(reason: "Carrete optimizado: no hay ráfagas ni tomas duplicadas pendientes.")
                return
            }

            state = .analyzing(progress: 0.5, message: "Evaluando nitidez y calidad con Vision...")

            var evaluatedClusters: [BurstCluster] = []
            let totalClusters = Float(rawClusters.count)

            for (index, cluster) in rawClusters.enumerated() {
                var evaluatedCandidates: [PhotoCandidate] = []

                for candidate in cluster.items {
                    let assessment: QualityAssessment
                    do {
                        let data = try await photoLibraryService.fetchImageData(
                            for: candidate.id,
                            targetSize: CGSize(width: 512, height: 512)
                        )
                        assessment = try await qualityEvaluator.evaluateQuality(for: data)
                    } catch {
                        // NFR-5: Resiliencia ante fallos de carga en imagen individual
                        assessment = QualityAssessment(sharpnessScore: 0.5, exposureScore: 0.5, compositeScore: 0.5)
                    }
                    evaluatedCandidates.append(PhotoCandidate(asset: candidate.asset, assessment: assessment))
                }

                // Re-agrupar el lote con las métricas calculadas para definir el keeper recomendado
                let recomputed = clusteringService.clusterize(candidates: evaluatedCandidates, timeThresholdSeconds: 5.0)
                evaluatedClusters.append(contentsOf: recomputed)

                let progress = 0.5 + (Float(index + 1) / totalClusters) * 0.45
                state = .analyzing(progress: progress, message: "Evaluando lote \(index + 1) de \(rawClusters.count)...")
            }

            if evaluatedClusters.isEmpty {
                state = .empty(reason: "Carrete optimizado: no hay fotos pendientes de descarte.")
            } else {
                state = .loaded(clusters: evaluatedClusters)
            }
        } catch let appError as AppError {
            state = .error(appError)
        } catch {
            state = .error(.unexpected(message: error.localizedDescription))
        }
    }

    /// Alterna la condición de una foto como 'Keeper' (soporta multi-keeper - FR-9, US-3).
    public func toggleKeeper(photoId: String, in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        var cluster = clusters[index]

        if cluster.keeperIds.contains(photoId) {
            // Si hay más de un keeper, se puede remover de keepers y pasar a discards
            if cluster.keeperIds.count > 1 {
                cluster.keeperIds.remove(photoId)
                cluster.discardIds.insert(photoId)
            }
        } else {
            // Agregar a keepers y remover de discards
            cluster.keeperIds.insert(photoId)
            cluster.discardIds.remove(photoId)
        }

        clusters[index] = cluster
        state = .loaded(clusters: clusters)
    }

    /// Marca todo el lote para descarte si el usuario considera que toda la ráfaga es basura digital (FR-10, US-4).
    public func discardAll(in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        var cluster = clusters[index]
        cluster.keeperIds.removeAll()
        cluster.discardIds = Set(cluster.items.map { $0.id })

        clusters[index] = cluster
        state = .loaded(clusters: clusters)
    }

    /// Conserva todo el lote sin descartar nada y lo archiva como revisado (FR-11, US-5, EC-4).
    public func keepAll(in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        clusters.remove(at: index)

        if clusters.isEmpty {
            state = .empty(reason: "Todos los lotes fueron revisados con éxito.")
        } else {
            state = .loaded(clusters: clusters)
        }
    }

    /// Confirma la depuración de las fotos marcadas para descarte en un lote (FR-12, NFR-4).
    /// Invoca el diálogo nativo de papelera del sistema.
    public func confirmDiscards(for clusterId: UUID) async -> Bool {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return false }

        let cluster = clusters[index]
        let idsToDelete = Array(cluster.discardIds)

        guard !idsToDelete.isEmpty else {
            // No hay nada que borrar, archivar como resuelto
            keepAll(in: clusterId)
            return true
        }

        do {
            let success = try await photoLibraryService.deleteAssets(withIDs: idsToDelete)
            guard success else {
                // EC-6: El usuario canceló el diálogo nativo, conservar estado
                return false
            }

            clusters.remove(at: index)
            if clusters.isEmpty {
                state = .empty(reason: "¡Limpieza completada! El carrete está al día.")
            } else {
                state = .loaded(clusters: clusters)
            }
            return true
        } catch let appError as AppError {
            state = .error(appError)
            return false
        } catch {
            state = .error(.unexpected(message: error.localizedDescription))
            return false
        }
    }
}
