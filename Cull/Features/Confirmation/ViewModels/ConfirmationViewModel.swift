import Foundation
import SwiftUI
import OSLog

/// Estados posibles de la pantalla de confirmación y depuración final (Paso 4).
public enum ConfirmationViewState: Equatable, Sendable {
    case ready
    case presentingWarningModal
    case purging
    case completed
    case error(String)
}

/// ViewModel responsable de la lógica del Paso 4 (Revisión Final, Modal y Depuración Exitosa).
/// Conforme a Swift 6 (`@Observable`, `@MainActor`, `Sendable`).
@Observable
@MainActor
public final class ConfirmationViewModel {
    public private(set) var state: ConfirmationViewState = .ready

    public let markedPhotoIds: [String]
    public let totalByteSize: Int64
    public let periodDescription: String
    public let triageMode: TriageMode
    public let photoLibraryService: PhotoLibraryServiceProtocol
    private let logger = Logger(subsystem: "com.gabrielsanchez.cull", category: "ConfirmationViewModel")

    public init(
        markedPhotoIds: [String],
        totalByteSize: Int64,
        periodDescription: String,
        triageMode: TriageMode,
        photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService()
    ) {
        self.markedPhotoIds = markedPhotoIds
        self.totalByteSize = totalByteSize
        self.periodDescription = periodDescription
        self.triageMode = triageMode
        self.photoLibraryService = photoLibraryService
    }

    /// Si hay 0 fotos seleccionadas, la depuración se deshabilita (FR-7, EC-1).
    public var isPurgeDisabled: Bool {
        markedPhotoIds.isEmpty
    }

    /// Representación legible del espacio recuperable (ej. "16.8 MB" o "0 B").
    public var formattedRecoverableSpace: String {
        ByteCountFormatter.string(fromByteCount: totalByteSize, countStyle: .file)
    }

    /// Rótulo descriptivo del tipo de depuración según el modo (FR-4, Assumption 3).
    public var triageTypeDescription: String {
        switch triageMode {
        case .burst:
            return "Tomas redundantes"
        case .noFace:
            return "Fotos sin rostro"
        }
    }

    /// Rótulo para el subtítulo de la pantalla de éxito (FR-13).
    public var modeSubtitleText: String {
        switch triageMode {
        case .burst:
            return "redundantes"
        case .noFace:
            return "sin rostro"
        }
    }

    /// Consejo semanal contextual de mantenimiento (FR-15).
    public var tipText: String {
        switch triageMode {
        case .burst:
            return "Revisa tus fotos semanalmente para mantener tu galería libre de ráfagas accidentales."
        case .noFace:
            return "Revisa tus fotos periódicamente para mantener tu galería libre de comprobantes y fotos descartables."
        }
    }

    /// Solicita abrir el modal de advertencia destructiva (FR-8).
    public func requestPurge() {
        guard !isPurgeDisabled else { return }
        state = .presentingWarningModal
    }

    /// Cierra el modal de advertencia sin alterar la selección (FR-9).
    public func dismissWarningModal() {
        state = .ready
    }

    /// Confirma la depuración invocando la API nativa de PhotoKit (FR-8, FR-10, FR-11).
    public func confirmPurge() async -> Bool {
        guard !markedPhotoIds.isEmpty else { return false }
        state = .purging

        do {
            let success = try await photoLibraryService.deleteAssets(withIDs: markedPhotoIds)
            if success {
                state = .completed
                return true
            } else {
                // EC-2: El usuario canceló el diálogo nativo de iOS
                state = .ready
                return false
            }
        } catch {
            state = .error(error.localizedDescription)
            return false
        }
    }
}
