import Foundation
import SwiftUI

/// Categorías semánticas para fotos sin rostros humanos (Assumption 1, FR-4, FR-5, FR-6).
public enum FacelessCategory: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable {
    case utilitarian = "utilitarian"
    case deficient = "deficient"
    case toValidate = "toValidate"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .utilitarian:
            return "Utilitarias"
        case .deficient:
            return "Deficientes"
        case .toValidate:
            return "Por Validar"
        }
    }

    public var subtitle: String {
        switch self {
        case .utilitarian:
            return "Vouchers, recibos, documentos y capturas"
        case .deficient:
            return "Fotos borrosas, oscuras o accidentales"
        case .toValidate:
            return "Fotos intencionales (paisajes, mascotas, comida)"
        }
    }

    public var systemImage: String {
        switch self {
        case .utilitarian:
            return "doc.text.viewfinder"
        case .deficient:
            return "camera.metering.unknown"
        case .toValidate:
            return "questionmark.circle"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .utilitarian:
            return .orange
        case .deficient:
            return .red
        case .toValidate:
            return .blue
        }
    }

    /// Indica si esta categoría se preselecciona para descarte por defecto (Assumption 2, FR-7).
    public var defaultPreselected: Bool {
        switch self {
        case .utilitarian, .deficient:
            return true
        case .toValidate:
            return false
        }
    }
}

/// Candidata a triaje de foto sin rostro.
public struct FacelessPhotoCandidate: Identifiable, Sendable, Equatable {
    public var id: String { asset.id }
    public let asset: PhotoAsset
    public let category: FacelessCategory
    public let textDetectedCount: Int
    public let sharpnessScore: Float
    public let luminanceScore: Float
    public var isSelected: Bool

    public init(
        asset: PhotoAsset,
        category: FacelessCategory,
        textDetectedCount: Int = 0,
        sharpnessScore: Float = 0.5,
        luminanceScore: Float = 0.5,
        isSelected: Bool
    ) {
        self.asset = asset
        self.category = category
        self.textDetectedCount = textDetectedCount
        self.sharpnessScore = sharpnessScore
        self.luminanceScore = luminanceScore
        self.isSelected = isSelected
    }
}

/// Grupo de fotos sin rostro bajo una categoría semántica específica.
public struct FacelessTriageGroup: Identifiable, Sendable, Equatable {
    public var id: String { category.id }
    public let category: FacelessCategory
    public var candidates: [FacelessPhotoCandidate]

    public init(category: FacelessCategory, candidates: [FacelessPhotoCandidate] = []) {
        self.category = category
        self.candidates = candidates
    }

    public var totalCount: Int {
        candidates.count
    }

    public var selectedCount: Int {
        candidates.filter { $0.isSelected }.count
    }

    public var allSelected: Bool {
        !candidates.isEmpty && selectedCount == totalCount
    }

    public var noneSelected: Bool {
        selectedCount == 0
    }

    /// Espacio en bytes recuperable de los elementos seleccionados en este grupo (FR-10).
    public var recoverableByteSize: Int64 {
        candidates
            .filter { $0.isSelected }
            .reduce(0) { $0 + $1.asset.byteSize }
    }
}

/// Estados posibles de la vista de depuración de fotos sin rostros.
public enum NoFaceTriageViewState: Equatable, Sendable {
    case idle
    case selectingDate
    case analyzing(progress: Float, message: String)
    case loaded(groups: [FacelessTriageGroup])
    case processingDiscard
    case empty(reason: String)
    case error(AppError)
}
