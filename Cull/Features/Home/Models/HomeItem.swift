import Foundation

/// Modelo de datos inmutable para elementos de la vista principal.
/// Cumple con `Identifiable` y `Sendable` para garantizar seguridad de concurrencia.
public struct HomeItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let subtitle: String

    public init(id: UUID = UUID(), title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
