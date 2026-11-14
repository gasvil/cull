import SwiftUI

/// Estado de la pantalla principal.
public enum HomeViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded([HomeItem])
    case error(String)
}

/// ViewModel responsable de la lógica y estado de la pantalla Home.
/// Implementa `@Observable` y `@MainActor` bajo los estándares de Swift 6 / iOS 17+.
@Observable
@MainActor
public final class HomeViewModel {
    public private(set) var state: HomeViewState = .idle

    public init() {}

    /// Carga los datos iniciales de la vista.
    public func loadInitialData() {
        state = .loading
        // Simulación inicial de datos en memoria (sin persistencia pesada anticipada - YAGNI)
        let items: [HomeItem] = [
            HomeItem(title: "Bienvenido a Cull", subtitle: "Esqueleto base inicializado correctamente."),
            HomeItem(title: "Arquitectura Limpia", subtitle: "SwiftUI + @Observable + Swift 6.")
        ]
        state = .loaded(items)
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
