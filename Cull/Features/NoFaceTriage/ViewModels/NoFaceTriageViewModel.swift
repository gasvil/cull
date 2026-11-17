import Foundation
import SwiftUI
import OSLog

/// ViewModel reactivo para la depuración de fotos sin rostros.
/// Gestiona la interacción con los servicios de biblioteca y clasificación visual,
/// la preselección inicial y la eliminación en lote (FR-1 a FR-13).
@Observable
@MainActor
public final class NoFaceTriageViewModel {
    public private(set) var state: NoFaceTriageViewState = .idle

    // Filtros de fecha configurables por el usuario
    public var filterMode: DateFilterMode = .today
    public var selectedSingleDate: Date = Date()
    public var selectedStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    public var selectedEndDate: Date = Date()
    public var periodDescription: String = "Últimos 7 días"

    // Categoría activa del selector por pestañas (Assumption 1, FR-4, FR-5)
    public var selectedCategory: FacelessCategory = .utilitarian

    // Previsualización modal de inspección (FR-13)
    public var previewCandidate: PhotoCandidate? = nil

    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let classifierService: FacelessClassificationServiceProtocol
    private let logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "NoFaceTriageViewModel")

    /// Caché del último análisis (FR-12, EC-7)
    private var cachedAssetSignature: [String] = []
    private var cachedDateRange: (start: Date, end: Date)?
    private var cachedGroups: [FacelessTriageGroup] = []

    public init(
        photoLibraryService: PhotoLibraryServiceProtocol,
        classifierService: FacelessClassificationServiceProtocol
    ) {
        self.photoLibraryService = photoLibraryService
        self.classifierService = classifierService
    }

    /// Espacio acumulado total recuperable entre todas las fotos seleccionadas (FR-10).
    public var totalRecoverableByteSize: Int64 {
        guard case .loaded(let groups) = state else { return 0 }
        return groups.reduce(0) { $0 + $1.recoverableByteSize }
    }

    /// Número total de fotos seleccionadas para descarte en todas las categorías (FR-15).
    public var totalSelectedCount: Int {
        guard case .loaded(let groups) = state else { return 0 }
        return groups.reduce(0) { $0 + $1.selectedCount }
    }

    /// Identificadores de todos los activos marcados para descarte entre todas las categorías (FR-16).
    public var allSelectedCandidateIds: [String] {
        guard case .loaded(let groups) = state else { return [] }
        return groups.flatMap { $0.candidates.filter { $0.isSelected }.map { $0.id } }
    }

    /// Número total de fotos candidatas analizadas sin rostros (FR-2).
    public var totalCandidatesCount: Int {
        guard case .loaded(let groups) = state else { return 0 }
        return groups.reduce(0) { $0 + $1.totalCount }
    }

    /// Cambia la pestaña de categoría activa (FR-5).
    public func selectCategory(_ category: FacelessCategory) {
        selectedCategory = category
    }

    /// Retorna el grupo correspondiente a una categoría.
    public func group(for category: FacelessCategory) -> FacelessTriageGroup? {
        guard case .loaded(let groups) = state else { return nil }
        return groups.first(where: { $0.category == category })
    }

    /// Indica si todas las fotos de la categoría especificada están marcadas (FR-7).
    public func isAllSelected(in category: FacelessCategory) -> Bool {
        guard let group = group(for: category) else { return false }
        return group.allSelected
    }

    /// Alterna la selección masiva de la categoría: desmarca si todas están seleccionadas, marca si hay selección parcial o ninguna (FR-7).
    public func toggleCategoryBulkSelection(for category: FacelessCategory) {
        if isAllSelected(in: category) {
            deselectAll(in: category)
        } else {
            selectAll(in: category)
        }
    }

    /// Obtiene el rango de fechas (inicio y fin) según la opción seleccionada (FR-1).
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

    /// Prepara la pantalla iniciando el análisis si hay un rango preconfigurado, o mostrando el selector si no
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
                    await loadAndAnalyze()
                }
            } else {
                state = .selectingDate
            }
        }
    }

    /// Vuelve al selector de fechas para definir un nuevo período.
    public func changeDateFilter() {
        state = .selectingDate
    }

    /// Configura directamente el rango de fechas desde el selector de período
    public func setDateRange(start: Date, end: Date) {
        self.filterMode = .dateRange
        self.selectedStartDate = start
        self.selectedEndDate = end
    }

    /// Carga las fotos del período, excluye favoritas y fotos con rostros, y las clasifica.
    /// Si los filtros y las fotos no cambiaron, restaura inmediatamente el caché (FR-12, EC-7).
    public func loadAndAnalyze(forceRefresh: Bool = false) async {
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

            // EC-2: Período sin fotos
            guard !assets.isEmpty else {
                cachedAssetSignature = []
                cachedDateRange = nil
                cachedGroups = []
                state = .empty(reason: "No se encontraron fotos en el período seleccionado.")
                return
            }

            // FR-3 & Assumption 3: Blindaje estricto de Favoritas (excluidas al 100%)
            let nonFavoriteAssets = assets.filter { !$0.isFavorite }

            // EC-3: Todas las fotos del período son favoritas
            guard !nonFavoriteAssets.isEmpty else {
                cachedAssetSignature = []
                cachedDateRange = nil
                cachedGroups = []
                state = .empty(reason: "Todas las fotos de este período están protegidas como favoritas.")
                return
            }

            let currentSignature = nonFavoriteAssets.map { $0.id }

            // FR-12 / EC-7: Comprobar caché inmediato si los filtros y fotos son idénticos
            if !forceRefresh,
               !cachedGroups.isEmpty,
               let cachedRange = cachedDateRange,
               cachedRange.start == range.start,
               cachedRange.end == range.end,
               currentSignature == cachedAssetSignature {
                state = .loaded(groups: cachedGroups)
                return
            }

            state = .analyzing(progress: 0.1, message: "Buscando fotos sin personas...")

            var candidates: [FacelessPhotoCandidate] = []
            let totalCount = Float(nonFavoriteAssets.count)

            for (index, asset) in nonFavoriteAssets.enumerated() {
                let classification: FacelessClassificationResult
                do {
                    let data = try await photoLibraryService.fetchImageData(
                        for: asset.id,
                        targetSize: CGSize(width: 512, height: 512)
                    )
                    classification = try await classifierService.classify(imageData: data)
                } catch {
                    // NFR-5: Resiliencia ante imagen corrupta o error de lectura
                    classification = FacelessClassificationResult(hasFaces: false, category: .toValidate)
                }

                // FR-2: Si tiene rostros humanos, se excluye del módulo
                if !classification.hasFaces, let category = classification.category {
                    // FR-7: Utilitarias y Deficientes preseleccionadas; Por Validar desmarcada por defecto
                    let isPreselected = category.defaultPreselected
                    let candidate = FacelessPhotoCandidate(
                        asset: asset,
                        category: category,
                        textDetectedCount: classification.textCount,
                        sharpnessScore: classification.sharpnessScore,
                        luminanceScore: classification.luminanceScore,
                        isSelected: isPreselected
                    )
                    candidates.append(candidate)
                }

                let progress = 0.1 + (Float(index + 1) / totalCount) * 0.85
                state = .analyzing(progress: progress, message: "Clasificando foto \(index + 1) de \(nonFavoriteAssets.count)...")
            }

            // EC-1: Todas las fotos tienen rostros
            guard !candidates.isEmpty else {
                cachedAssetSignature = currentSignature
                cachedDateRange = range
                cachedGroups = []
                state = .empty(reason: "No se encontraron fotos sin personas en este período.")
                return
            }

            // FR-13 / EC-4: Garantizar que TODAS las categorías estén presentes, incluso si tienen 0 fotos
            let groups = FacelessCategory.allCases.map { cat in
                FacelessTriageGroup(
                    category: cat,
                    candidates: candidates.filter { $0.category == cat }
                )
            }

            cachedAssetSignature = currentSignature
            cachedDateRange = range
            cachedGroups = groups
            state = .loaded(groups: groups)

        } catch let appError as AppError {
            state = .error(appError)
        } catch {
            state = .error(.unexpected(message: error.localizedDescription))
        }
    }

    /// Alterna la selección de una foto individual en su cuadrícula (FR-8).
    public func toggleSelection(candidateId: String) {
        guard case .loaded(var groups) = state else { return }

        for groupIndex in groups.indices {
            if let candidateIndex = groups[groupIndex].candidates.firstIndex(where: { $0.id == candidateId }) {
                groups[groupIndex].candidates[candidateIndex].isSelected.toggle()
                break
            }
        }

        cachedGroups = groups
        state = .loaded(groups: groups)
    }

    /// Selecciona todas las fotos de una categoría específica (FR-9).
    public func selectAll(in category: FacelessCategory) {
        guard case .loaded(var groups) = state,
              let groupIndex = groups.firstIndex(where: { $0.category == category }) else { return }

        for candidateIndex in groups[groupIndex].candidates.indices {
            groups[groupIndex].candidates[candidateIndex].isSelected = true
        }

        cachedGroups = groups
        state = .loaded(groups: groups)
    }

    /// Deselecciona todas las fotos de una categoría específica (FR-9).
    public func deselectAll(in category: FacelessCategory) {
        guard case .loaded(var groups) = state,
              let groupIndex = groups.firstIndex(where: { $0.category == category }) else { return }

        for candidateIndex in groups[groupIndex].candidates.indices {
            groups[groupIndex].candidates[candidateIndex].isSelected = false
        }

        cachedGroups = groups
        state = .loaded(groups: groups)
    }

    /// Confirma la depuración de las fotos seleccionadas y llama a la papelera nativa (FR-11, NFR-4).
    public func confirmDiscards() async -> Bool {
        guard case .loaded(var groups) = state else { return false }

        var idsToDelete: [String] = []
        for group in groups {
            idsToDelete.append(contentsOf: group.candidates.filter { $0.isSelected }.map { $0.id })
        }

        guard !idsToDelete.isEmpty else { return true }

        let previousState = state
        state = .processingDiscard

        do {
            let success = try await photoLibraryService.deleteAssets(withIDs: idsToDelete)
            guard success else {
                // EC-5: El usuario canceló el diálogo nativo, restaurar selección intacta
                state = previousState
                return false
            }

            let deletedSet = Set(idsToDelete)
            for groupIndex in groups.indices {
                groups[groupIndex].candidates.removeAll { deletedSet.contains($0.id) }
            }

            let remainingTotal = groups.reduce(0) { $0 + $1.totalCount }
            if remainingTotal == 0 {
                cachedGroups = []
                state = .empty(reason: "¡Limpieza completada! El carrete está al día.")
            } else {
                cachedGroups = groups
                state = .loaded(groups: groups)
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
