import SwiftUI

/// Nivel de prioridad visual para tarjetas de categoría.
public enum CategoryPriority: String, Sendable {
    case high = "Alta Prioridad"
    case medium = "Prioridad Media"
    case low = "Baja Prioridad"

    public var containerColor: Color {
        switch self {
        case .high:
            return AppColor.cullContainer
        case .medium:
            return AppColor.pendingContainer
        case .low:
            return AppColor.surfaceContainerHigh
        }
    }

    public var foregroundColor: Color {
        switch self {
        case .high:
            return AppColor.onCullContainer
        case .medium:
            return AppColor.onPendingContainer
        case .low:
            return AppColor.onSurfaceVariant
        }
    }
}

/// Tarjeta de categoría semántica para el módulo de depuración (`ds.md` - Cards).
/// Reproduce exactamente la tarjeta visual de "Utilitarias" del sistema de diseño.
public struct CategoryCard: View {
    public let title: String
    public let priority: CategoryPriority
    public let description: String
    public let count: Int
    public let byteSize: Int64
    public let systemImage: String?
    public let actionTitle: String
    public let onAction: () -> Void

    public init(
        title: String,
        priority: CategoryPriority = .high,
        description: String,
        count: Int,
        byteSize: Int64,
        systemImage: String? = "circle.fill",
        actionTitle: String = "Revisar lote ›",
        onAction: @escaping () -> Void
    ) {
        self.title = title
        self.priority = priority
        self.description = description
        self.count = count
        self.byteSize = byteSize
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        CullCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Cabecera: Título + Badge de Prioridad
                HStack(alignment: .center) {
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        if let systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(priority == .high ? AppColor.cull : AppColor.pending)
                        }
                        Text(title)
                            .font(AppFont.headlineSmall)
                            .foregroundColor(AppColor.onSurface)
                    }

                    Spacer()

                    // Badge de Prioridad
                    Text(priority.rawValue)
                        .font(AppFont.labelSmall)
                        .bold()
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.xxSmall)
                        .background(priority.containerColor)
                        .foregroundColor(priority.foregroundColor)
                        .clipShape(Capsule())
                }

                // Descripción
                Text(description)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .lineLimit(2)

                // Pie: Estadísticas de fotos + Acción
                HStack(alignment: .center) {
                    let formattedSize = ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
                    let countText = count == 1 ? "1 foto" : "\(count) fotos"
                    Text("\(countText) · \(formattedSize)")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)

                    Spacer()

                    Button(action: onAction) {
                        Text(actionTitle)
                            .font(AppFont.labelLarge)
                            .bold()
                            .foregroundColor(AppColor.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Abre la revisión detallada de este lote")
                }
                .padding(.top, AppTheme.Spacing.xxSmall)
            }
        }
    }
}

#Preview("Category Card") {
    CategoryCard(
        title: "Utilitarias",
        priority: .high,
        description: "Comprobantes, capturas de pantalla y documentos listos para depurar",
        count: 0,
        byteSize: 0,
        actionTitle: "Revisar lote ›"
    ) {}
    .padding()
}
