import SwiftUI
import OSLog

/// Contenedor de dependencias raíz de la aplicación.
/// Diseñado para facilitar la inyección de dependencias y pruebas unitarias (DIP / P7).
@Observable
@MainActor
public final class AppEnvironment {
    public let router: AppRouter
    public let logger: Logger

    public init(
        router: AppRouter = AppRouter(),
        logger: Logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "App")
    ) {
        self.router = router
        self.logger = logger
    }
}
