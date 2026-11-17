import Foundation

/// Representación desacoplada de una fotografía de la biblioteca.
public struct PhotoAsset: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let creationDate: Date
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let byteSize: Int64
    public let isFavorite: Bool
    public let burstIdentifier: String?
    public let representsBurst: Bool

    public init(
        id: String,
        creationDate: Date,
        pixelWidth: Int,
        pixelHeight: Int,
        byteSize: Int64,
        isFavorite: Bool,
        burstIdentifier: String? = nil,
        representsBurst: Bool = false
    ) {
        self.id = id
        self.creationDate = creationDate
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteSize = byteSize
        self.isFavorite = isFavorite
        self.burstIdentifier = burstIdentifier
        self.representsBurst = representsBurst
    }
}

/// Evaluación facial de calidad (apertura de ojos, parpadeos).
public struct FaceAssessment: Sendable, Equatable, Hashable {
    public let faceCount: Int
    public let allEyesOpen: Bool
    public let openEyesConfidence: Float

    public init(faceCount: Int, allEyesOpen: Bool, openEyesConfidence: Float) {
        self.faceCount = faceCount
        self.allEyesOpen = allEyesOpen
        self.openEyesConfidence = openEyesConfidence
    }
}

/// Evaluación objetiva de calidad para una fotografía.
public struct QualityAssessment: Sendable, Equatable, Hashable {
    public let sharpnessScore: Float          // 0.0 - 1.0 (FR-2)
    public let exposureScore: Float           // 0.0 - 1.0
    public let faceAssessment: FaceAssessment? // nil si no hay rostros (FR-3, EC-5)
    public let compositeScore: Float          // Ponderado final 0.0 - 1.0 (FR-4)

    public init(
        sharpnessScore: Float,
        exposureScore: Float,
        faceAssessment: FaceAssessment? = nil,
        compositeScore: Float
    ) {
        self.sharpnessScore = sharpnessScore
        self.exposureScore = exposureScore
        self.faceAssessment = faceAssessment
        self.compositeScore = compositeScore
    }
}

/// Candidata a triaje dentro de un grupo con su evaluación asociada.
public struct PhotoCandidate: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { asset.id }
    public let asset: PhotoAsset
    public let assessment: QualityAssessment?

    public init(asset: PhotoAsset, assessment: QualityAssessment? = nil) {
        self.asset = asset
        self.assessment = assessment
    }
}

/// Estado de resolución de un grupo de triaje.
public enum ClusterReviewStatus: Sendable, Equatable {
    case pending
    case reviewedKept
    case reviewedDiscarded
}

/// Agrupación de fotos similares o ráfagas evaluadas.
public struct BurstCluster: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let items: [PhotoCandidate]
    public var keeperIds: Set<String>     // Permite múltiples keepers (FR-9)
    public var discardIds: Set<String>    // Candidatas actuales a descarte (FR-6)
    public var status: ClusterReviewStatus

    public init(
        id: UUID = UUID(),
        items: [PhotoCandidate],
        keeperIds: Set<String> = [],
        discardIds: Set<String> = [],
        status: ClusterReviewStatus = .pending
    ) {
        self.id = id
        self.items = items
        self.keeperIds = keeperIds
        self.discardIds = discardIds
        self.status = status
    }

    /// Espacio en bytes recuperable al purgar las fotos marcadas en discardIds (FR-8).
    public var recoverableByteSize: Int64 {
        items
            .filter { discardIds.contains($0.id) }
            .reduce(0) { $0 + $1.asset.byteSize }
    }

    /// Candidata destacada actual (la primera en keeperIds o la primera del grupo).
    public var primaryWinner: PhotoCandidate? {
        items.first(where: { keeperIds.contains($0.id) }) ?? items.first
    }

    /// Hora formateada de la primera toma del lote (ej. "11:24 AM").
    public var formattedTime: String {
        guard let firstDate = items.first?.asset.creationDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: firstDate)
    }

    /// Fecha corta formateada de la primera toma del lote (ej. "16 Nov").
    public var formattedDate: String {
        guard let firstDate = items.first?.asset.creationDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: firstDate)
    }

    public var isAllDiscarded: Bool {
        !items.isEmpty && discardIds.count == items.count
    }

    public var isAllKept: Bool {
        discardIds.isEmpty
    }
}
