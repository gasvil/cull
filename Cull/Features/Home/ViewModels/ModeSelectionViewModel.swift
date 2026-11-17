import Foundation
import SwiftUI

/// ViewModel responsable de la selección de algoritmo de depuración en el Paso 2.
@Observable
@MainActor
public final class ModeSelectionViewModel {
    public var selectedMode: TriageMode = .burst
    public let startDate: Date
    public let endDate: Date
    public let periodDescription: String

    public init(startDate: Date, endDate: Date, periodDescription: String = "") {
        self.startDate = startDate
        self.endDate = endDate
        self.periodDescription = periodDescription
    }

    /// Selecciona de manera unívoca el modo de depuración (FR-9, Assumption 3).
    public func selectMode(_ mode: TriageMode) {
        selectedMode = mode
    }

    /// Lanza directamente el análisis del modo seleccionado con el período resuelto (FR-10).
    public func startAnalysis(environment: AppEnvironment) {
        switch selectedMode {
        case .burst:
            let burstVM = environment.makeBurstTriageViewModel()
            burstVM.setDateRange(start: startDate, end: endDate)
            burstVM.periodDescription = periodDescription
            Task {
                await burstVM.loadAndAnalyzeClusters()
            }
            environment.router.navigate(to: .burstTriage)

        case .noFace:
            let noFaceVM = environment.makeNoFaceTriageViewModel()
            noFaceVM.setDateRange(start: startDate, end: endDate)
            noFaceVM.periodDescription = periodDescription
            Task {
                await noFaceVM.loadAndAnalyze()
            }
            environment.router.navigate(to: .noFaceTriage)
        }
    }
}
