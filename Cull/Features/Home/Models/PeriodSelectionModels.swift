import Foundation
import SwiftUI

/// Opciones de período temporal para el Paso 1 (Home).
public enum PeriodOption: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable {
    case today = "today"
    case last7Days = "last7Days"
    case thisMonth = "thisMonth"
    case custom = "custom"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today:
            return "Hoy"
        case .last7Days:
            return "Últimos 7 días"
        case .thisMonth:
            return "Este mes"
        case .custom:
            return "Personalizado"
        }
    }

    public var defaultSubtitle: String {
        switch self {
        case .today:
            return "Fotos capturadas en las últimas 24 horas"
        case .last7Days:
            return "Semana en curso"
        case .thisMonth:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_PE")
            formatter.dateFormat = "LLLL yyyy"
            let monthYear = formatter.string(from: Date()).capitalized
            return monthYear
        case .custom:
            return "Elegir fecha o rango específico"
        }
    }

    public var systemImage: String {
        switch self {
        case .today:
            return "sun.max"
        case .last7Days:
            return "calendar"
        case .thisMonth:
            return "calendar.badge.clock"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

/// Modo de fecha cuando se selecciona 'Personalizado'.
public enum CustomDateMode: String, CaseIterable, Identifiable, Sendable, Equatable {
    case singleDate = "Día único"
    case dateRange = "Rango de fechas"

    public var id: String { rawValue }
}

/// Modos de depuración de fotos disponibles para el Paso 2.
public enum TriageMode: String, CaseIterable, Identifiable, Sendable, Equatable, Hashable {
    case burst = "burst"
    case noFace = "noFace"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .burst:
            return "Ráfagas"
        case .noFace:
            return "Sin Rostro"
        }
    }

    public var badgeTitle: String {
        switch self {
        case .burst:
            return "SMART PICK"
        case .noFace:
            return "3 CATEGORÍAS"
        }
    }

    public var systemImage: String {
        switch self {
        case .burst:
            return "square.stack.3d.down.right.fill"
        case .noFace:
            return "person.slash.fill"
        }
    }

    public var description: String {
        switch self {
        case .burst:
            return "Conserva solo la mejor toma. Agrupa capturas consecutivas y preselecciona los descartes redundantes."
        case .noFace:
            return "Vouchers, capturas y fotos descartables. Encuentra documentos, tomas accidentales oscuras o fotos a validar."
        }
    }
}
