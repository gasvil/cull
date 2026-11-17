import Foundation
import SwiftUI
import OSLog

/// Estado de la pantalla principal (Paso 1).
public enum HomeViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded([HomeItem])
    case error(String)
}

/// ViewModel responsable de la selección de período temporal en la pantalla Home (Paso 1).
/// Implementa `@Observable` y `@MainActor` bajo los estándares de Swift 6 / iOS 17+.
@Observable
@MainActor
public final class HomeViewModel {
    public private(set) var state: HomeViewState = .idle

    // Selección de período (FR-1, FR-2)
    public var selectedPeriod: PeriodOption = .last7Days
    public var selectedSingleDate: Date = Date()
    public var selectedStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    public var selectedEndDate: Date = Date()
    public var customDateMode: CustomDateMode = .singleDate

    // Conteo estimativo asíncrono no bloqueante (FR-4, NFR-1, NFR-2)
    public private(set) var activePhotoCount: Int? = nil
    public private(set) var isCalculatingCount: Bool = false

    public let photoLibraryService: PhotoLibraryServiceProtocol
    private var countTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "HomeViewModel")

    public init(photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService()) {
        self.photoLibraryService = photoLibraryService
    }

    /// Inicializa la vista con la opción por defecto ("Últimos 7 días") y consulta asíncrona de conteo (FR-1, FR-4).
    public func loadInitialData() {
        let items: [HomeItem] = [
            HomeItem(title: "Bienvenido a Cull", subtitle: "Curación inteligente de fotografías."),
            HomeItem(title: "Arquitectura Limpia", subtitle: "SwiftUI + @Observable + Swift 6.")
        ]
        state = .loaded(items)
        refreshPhotoCount()
    }

    /// Cambia la opción de período y actualiza el conteo en segundo plano (FR-2, EC-5).
    public func selectPeriod(_ option: PeriodOption) {
        selectedPeriod = option
        refreshPhotoCount()
    }

    /// Resuelve el intervalo temporal (fecha de inicio y fin) para el período seleccionado.
    public func resolveCurrentDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .today:
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
            return (start, end)

        case .last7Days:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            let start = calendar.startOfDay(for: sevenDaysAgo)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
            return (start, end)

        case .thisMonth:
            let now = Date()
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? now
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            let end = calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? now
            return (start, end)

        case .custom:
            // EC-2: Normalización automática si fecha inicio > fin
            if customDateMode == .singleDate {
                let start = calendar.startOfDay(for: selectedSingleDate)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedSingleDate) ?? selectedSingleDate
                return (start, end)
            } else {
                let actualStart = min(selectedStartDate, selectedEndDate)
                let actualEnd = max(selectedStartDate, selectedEndDate)
                let start = calendar.startOfDay(for: actualStart)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: actualEnd) ?? actualEnd
                return (start, end)
            }
        }
    }

    /// Actualiza el conteo de fotos de forma asíncrona y cancelable (FR-4, EC-5).
    public func refreshPhotoCount() {
        countTask?.cancel()
        countTask = Task { [weak self] in
            guard let self else { return }
            self.isCalculatingCount = true
            let range = self.resolveCurrentDateRange()

            do {
                let count = try await self.photoLibraryService.fetchAssetCount(
                    startDate: range.start,
                    endDate: range.end
                )
                guard !Task.isCancelled else { return }
                self.activePhotoCount = count
                self.isCalculatingCount = false
            } catch {
                guard !Task.isCancelled else { return }
                self.activePhotoCount = nil
                self.isCalculatingCount = false
            }
        }
    }

    /// Genera el subtítulo dinámico para una opción de período.
    public func subtitle(for option: PeriodOption) -> String {
        let base = option.defaultSubtitle
        if option == selectedPeriod, let count = activePhotoCount {
            return "\(base) · ~\(count) fotos"
        }
        return base
    }

    /// Agrega un nuevo elemento verificando precondiciones (P4 - Resilience).
    public func addItem(title: String, subtitle: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw AppError.invalidInput(reason: "El título no puede estar vacío.")
        }

        var currentItems: [HomeItem] = []
        if case .loaded(let items) = state {
            currentItems = items
        }

        let newItem = HomeItem(title: trimmedTitle, subtitle: subtitle)
        currentItems.append(newItem)
        state = .loaded(currentItems)
    }
}
