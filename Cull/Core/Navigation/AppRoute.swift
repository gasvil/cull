import SwiftUI

/// Rutas de navegación tipadas para la aplicación.
/// Permite navegación desacoplada y predecible (POLA / SoC).
public enum AppRoute: Hashable, Sendable {
    case home
    case modeSelection(startDate: Date, endDate: Date, periodDescription: String)
    case burstTriage
    case noFaceTriage
    case reviewConfirmation(markedPhotoIds: [String], totalByteSize: Int64, periodDescription: String, triageMode: TriageMode)
    case detail(title: String)
}
