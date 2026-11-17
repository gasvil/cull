import SwiftUI

/// Tarjeta descriptiva de la categoría activa con botón de acción masiva (FR-6, FR-7).
public struct FacelessCategoryHeaderCardView: View {
    public let group: FacelessTriageGroup
    public let onToggleBulkSelection: () -> Void

    public init(
        group: FacelessTriageGroup,
        onToggleBulkSelection: @escaping () -> Void
    ) {
        self.group = group
        self.onToggleBulkSelection = onToggleBulkSelection
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            // Icono de categoría en contenedor circular
            ZStack {
                Circle()
                    .fill(group.category.isHighPriority ? AppColor.cull : AppColor.pending)
                    .frame(width: 36, height: 36)

                Image(systemName: group.category.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Título, Badge de Prioridad y Descripción
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    Text(group.category.title)
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onSurface)

                    Text(group.category.priorityTitle)
                        .font(AppFont.labelSmall)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(group.category.isHighPriority ? AppColor.cull : AppColor.pending)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Text(group.category.subtitle)
                    .font(AppFont.monoSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            // Botón de acción masiva: "Desmarcar todas" o "Marcar todas" (FR-7)
            if group.totalCount > 0 {
                Button {
                    onToggleBulkSelection()
                } label: {
                    Text(group.allSelected ? "Desmarcar todas" : "Marcar todas")
                        .font(AppFont.labelMedium)
                        .bold()
                        .foregroundColor(AppColor.cull)
                        .multilineTextAlignment(.trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(group.allSelected ? "Desmarcar todas las fotos de \(group.category.title)" : "Marcar todas las fotos de \(group.category.title)")
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            group.category.isHighPriority
                ? AppColor.cullContainer.opacity(0.35)
                : AppColor.surfaceContainerLow
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .strokeBorder(
                    group.category.isHighPriority ? AppColor.cull.opacity(0.2) : AppColor.outlineVariant,
                    lineWidth: 1
                )
        )
    }
}
