import SwiftUI

/// Tarjeta de ráfaga/lote para revisión interactiva (`ds.md` - Cards).
/// Reproduce exactamente la tarjeta visual de "Ráfaga #12 (5 tomas)" del sistema de diseño.
public struct ClusterCard: View {
    public let title: String
    public let sizeFormatted: String
    public let description: String
    public let actionTitle: String
    public let isActionEnabled: Bool
    public let onAction: () -> Void

    public init(
        title: String,
        sizeFormatted: String,
        description: String,
        actionTitle: String = "Depurar",
        isActionEnabled: Bool = true,
        onAction: @escaping () -> Void
    ) {
        self.title = title
        self.sizeFormatted = sizeFormatted
        self.description = description
        self.actionTitle = actionTitle
        self.isActionEnabled = isActionEnabled
        self.onAction = onAction
    }

    public var body: some View {
        CullCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Cabecera: Título de ráfaga + Badge de peso
                HStack(alignment: .center) {
                    Text(title)
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onSurface)

                    Spacer()

                    // Badge de almacenamiento
                    Text(sizeFormatted)
                        .font(AppFont.monoSmall)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.xxSmall)
                        .background(AppColor.surfaceContainerHigh)
                        .foregroundColor(AppColor.onSurface)
                        .clipShape(Capsule())
                }

                // Descripción del estado
                Text(description)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .lineLimit(2)

                // Botón de acción rápida en la esquina inferior derecha
                HStack {
                    Spacer()

                    CullButton(
                        actionTitle,
                        variant: .destructive,
                        isFullWidth: false,
                        isCapsule: true,
                        action: onAction
                    )
                    .disabled(!isActionEnabled)
                }
                .padding(.top, AppTheme.Spacing.xxSmall)
            }
        }
    }
}

#Preview("Cluster Card") {
    ClusterCard(
        title: "Ráfaga #12 (5 tomas)",
        sizeFormatted: "6.4 GB",
        description: "1 foto marcada para guardar, 4 preseleccionadas para eliminar",
        actionTitle: "Depurar 4"
    ) {}
    .padding()
}
