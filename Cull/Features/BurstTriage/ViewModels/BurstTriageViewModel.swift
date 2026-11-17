import SwiftUI
import OSLog

/// Modos de selección de período para el análisis
public enum DateFilterMode: String, CaseIterable, Sendable {
    case today = "Hoy"
    case yesterday = "Ayer"
    case last7Days = "Últimos 7 días"
    case singleDate = "Día específico"
    case dateRange = "Rango de fechas"
}

/// Estados posibles de la pantalla de triaje de ráfagas.
public enum BurstTriageViewState: Equatable, Sendable {
    case idle
    case requestingPermission
    case selectingDate
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

    // Filtros de fecha configurables por el usuario
    public var filterMode: DateFilterMode = .today
    public var selectedSingleDate: Date = Date()
    public var selectedStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    public var selectedEndDate: Date = Date()

    public let photoLibraryService: PhotoLibraryServiceProtocol
    public var previewCandidate: PhotoCandidate? = nil
    private let clusteringService: BurstClusteringServiceProtocol
    private let qualityEvaluator: ImageQualityEvaluatorProtocol
    private let logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "BurstTriageViewModel")

    /// Cache del último análisis: guarda los IDs de las fotos analizadas y los clusters resultantes
    private var cachedAssetSignature: [String] = []
    private var cachedClusters: [BurstCluster] = []

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

    /// Cantidad total de fotos analizadas y agrupadas en ráfagas (FR-2).
    public var totalPhotosCount: Int {
        if case .loaded(let clusters) = state {
            return clusters.reduce(0) { $0 + $1.items.count }
        }
        return 0
    }

    /// Cantidad total consolidada de fotos marcadas para descarte (con indicador rojo) (FR-12).
    public var totalMarkedDiscardsCount: Int {
        if case .loaded(let clusters) = state {
            return clusters.reduce(0) { $0 + $1.discardIds.count }
        }
        return 0
    }

    /// Identificadores de todos los activos marcados para descarte en los lotes.
    public var allMarkedDiscardIds: [String] {
        if case .loaded(let clusters) = state {
            return clusters.flatMap { Array($0.discardIds) }
        }
        return []
    }

    /// Obtiene el rango de fechas (inicio y fin) según la opción seleccionada
    public func resolveCurrentDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch filterMode {
        case .today:
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
            return (start, end)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
            return (start, end)
        case .last7Days:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            let start = calendar.startOfDay(for: sevenDaysAgo)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
            return (start, end)
        case .singleDate:
            let start = calendar.startOfDay(for: selectedSingleDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedSingleDate) ?? selectedSingleDate
            return (start, end)
        case .dateRange:
            let start = calendar.startOfDay(for: min(selectedStartDate, selectedEndDate))
            let maxEnd = max(selectedStartDate, selectedEndDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: maxEnd) ?? maxEnd
            return (start, end)
        }
    }

    /// Prepara la pantalla ejecutando el análisis si hay un rango preconfigurado, o mostrando el selector si no
    public func prepareView() {
        if case .loaded = state {
            return
        }
        if case .analyzing = state {
            return
        }
        if case .idle = state {
            if filterMode == .dateRange {
                Task {
                    await loadAndAnalyzeClusters()
                }
            } else {
                state = .selectingDate
            }
        }
    }

    /// Permite volver al selector de fechas para buscar en otro período
    public func changeDateFilter() {
        state = .selectingDate
    }

    /// Configura directamente el rango de fechas desde el selector de período
    public func setDateRange(start: Date, end: Date) {
        self.filterMode = .dateRange
        self.selectedStartDate = start
        self.selectedEndDate = end
    }

    /// Carga las fotos para el período seleccionado, agrupa candidatos por ráfaga/ventana temporal y evalúa su calidad.
    /// Si el conjunto de fotos del período no ha cambiado, restaura el último análisis en memoria (FR-14).
    /// El parámetro `forceRefresh` permite ignorar el caché cuando el usuario lo solicite.
    public func loadAndAnalyzeClusters(forceRefresh: Bool = false) async {
        let isAuthorized = await photoLibraryService.requestAuthorization()
        guard isAuthorized else {
            state = .error(.unauthorized)
            return
        }

        let range = resolveCurrentDateRange()

        do {
            let assets = try await photoLibraryService.fetchAssets(
                startDate: range.start,
                endDate: range.end,
                limit: 300
            )
            guard !assets.isEmpty else {
                cachedAssetSignature = []
                cachedClusters = []
                state = .empty(reason: "No se encontraron fotos en el período seleccionado.")
                return
            }

            let currentSignature = assets.map { $0.id }

            // Comprobar si podemos reutilizar el análisis previo sin re-procesar (FR-14)
            if !forceRefresh,
               !cachedClusters.isEmpty,
               currentSignature == cachedAssetSignature {
                state = .loaded(clusters: cachedClusters)
                return
            }

            state = .analyzing(progress: 0.1, message: "Buscando fotos en la fecha seleccionada...")

            state = .analyzing(progress: 0.3, message: "Agrupando ráfagas y fotos similares...")
            let rawClusters = clusteringService.clusterize(assets: assets, timeThresholdSeconds: 5.0)

            guard !rawClusters.isEmpty else {
                cachedAssetSignature = currentSignature
                cachedClusters = []
                state = .empty(reason: "Carrete optimizado: no hay ráfagas ni fotos similares en esta fecha.")
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

            cachedAssetSignature = currentSignature
            cachedClusters = evaluatedClusters

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

    /// Promueve una foto como la única ganadora del lote, pasando la anterior a descarte (FR-10, US-2).
    public func setPrimaryWinner(photoId: String, in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        var cluster = clusters[index]
        cluster.keeperIds = [photoId]
        cluster.discardIds = Set(cluster.items.map { $0.id }).subtracting([photoId])
        cluster.status = .pending

        clusters[index] = cluster
        cachedClusters = clusters
        state = .loaded(clusters: clusters)
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
        cachedClusters = clusters
        state = .loaded(clusters: clusters)
    }

    /// Marca todo el lote para descarte; todos los indicadores pasan a rojo (FR-4, FR-6).
    public func discardAll(in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        var cluster = clusters[index]
        cluster.keeperIds.removeAll()
        cluster.discardIds = Set(cluster.items.map { $0.id })
        cluster.status = .reviewedDiscarded

        clusters[index] = cluster
        cachedClusters = clusters
        state = .loaded(clusters: clusters)
    }

    /// Conserva todo el lote; todos los indicadores pasan a verde (FR-4, FR-6).
    public func keepAll(in clusterId: UUID) {
        guard case .loaded(var clusters) = state,
              let index = clusters.firstIndex(where: { $0.id == clusterId }) else { return }

        var cluster = clusters[index]
        cluster.keeperIds = Set(cluster.items.map { $0.id })
        cluster.discardIds.removeAll()
        cluster.status = .reviewedKept

        clusters[index] = cluster
        cachedClusters = clusters
        state = .loaded(clusters: clusters)
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
            cachedClusters = clusters
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
