import SwiftUI
import OSLog

/// Contenedor de dependencias raíz de la aplicación.
/// Diseñado para facilitar la inyección de dependencias y pruebas unitarias (DIP / P7).
@Observable
@MainActor
public final class AppEnvironment {
    public let router: AppRouter
    public let logger: Logger
    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let clusteringService: BurstClusteringServiceProtocol
    public let qualityEvaluator: ImageQualityEvaluatorProtocol

    public init(
        router: AppRouter = AppRouter(),
        logger: Logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "App"),
        photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
        clusteringService: BurstClusteringServiceProtocol = BurstClusteringService(),
        qualityEvaluator: ImageQualityEvaluatorProtocol = VisionQualityEvaluator()
    ) {
        self.router = router
        self.logger = logger
        self.photoLibraryService = photoLibraryService
        self.clusteringService = clusteringService
        self.qualityEvaluator = qualityEvaluator
    }

    public func makeBurstTriageViewModel() -> BurstTriageViewModel {
        BurstTriageViewModel(
            photoLibraryService: photoLibraryService,
            clusteringService: clusteringService,
            qualityEvaluator: qualityEvaluator
        )
    }
}
