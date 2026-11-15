import SwiftUI

/// Rutas de navegación tipadas para la aplicación.
/// Permite navegación desacoplada y predecible (POLA / SoC).
public enum AppRoute: Hashable, Sendable {
    case home
    case burstTriage
    case detail(title: String)
}
