import SwiftUI

/// Vista de galería del sistema de diseño Cull que reproduce la hoja de componentes de `ds.md`.
public struct DesignSystemGalleryView: View {
    @State private var selectedChip: String = "Todas"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Cabecera
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title2)
                    Text("Components")
                        .font(AppFont.headlineLarge)
                    Text("3")
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                }
                .padding(.horizontal)

                // Fila 1: Buttons & Cards
                VStack(spacing: AppTheme.Spacing.medium) {
                    // SECCIÓN 1: BUTTONS
                    componentSection(
                        title: "Button",
                        subtitle: "Actions",
                        tags: ["Primary & Destructive", "Icon Buttons"]
                    ) {
                        VStack(spacing: AppTheme.Spacing.small) {
                            HStack(spacing: AppTheme.Spacing.small) {
                                CullButton("Analizar fotos", variant: .primary) {}
                                CullButton("Depurar seleccionadas", systemImage: "sparkles", variant: .destructive) {}
                            }
                            HStack(spacing: AppTheme.Spacing.small) {
                                CullButton("Conservar todas", variant: .secondary) {}
                                CullIconButton(systemImage: "trash.fill", accessibilityLabel: "Eliminar", tint: AppColor.cull) {}
                                CullIconButton(systemImage: "bookmark.fill", accessibilityLabel: "Guardar", tint: AppColor.keep) {}
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                    }

                    // SECCIÓN 2: CARDS
                    componentSection(
                        title: "Card",
                        subtitle: "Containment",
                        tags: ["Cluster & Category Cards", "Interactive Card"]
                    ) {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            CategoryCard(
                                title: "Utilitarias",
                                priority: .high,
                                description: "Comprobantes, capturas de pantalla y documentos listos para depurar",
                                count: 0,
                                byteSize: 0,
                                actionTitle: "Revisar lote ›"
                            ) {}

                            ClusterCard(
                                title: "Ráfaga #12 (5 tomas)",
                                sizeFormatted: "6.4 GB",
                                description: "1 foto marcada para guardar, 4 preseleccionadas para eliminar",
                                actionTitle: "Depurar 4"
                            ) {}
                        }
                    }

                    // SECCIÓN 3: CHIPS
                    componentSection(
                        title: "Chip",
                        subtitle: "Feedback",
                        tags: []
                    ) {
                        HStack(spacing: AppTheme.Spacing.small) {
                            CullChip(
                                "Todas",
                                variant: .neutral(dotColor: Color.blue),
                                isSelected: selectedChip == "Todas"
                            ) {
                                selectedChip = "Todas"
                            }

                            CullChip(
                                "Eliminar (4)",
                                variant: .cull,
                                isSelected: selectedChip == "Eliminar (4)"
                            ) {
                                selectedChip = "Eliminar (4)"
                            }

                            CullChip(
                                "Guardar (Mejor toma)",
                                variant: .keep,
                                isSelected: selectedChip == "Guardar (Mejor toma)"
                            ) {
                                selectedChip = "Guardar (Mejor toma)"
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.medium)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(AppColor.surface)
    }

    @ViewBuilder
    private func componentSection<Content: View>(
        title: String,
        subtitle: String,
        tags: [String],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            // Contenedor visual tipo mockup
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if !tags.isEmpty {
                    HStack(spacing: AppTheme.Spacing.xxSmall) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(AppFont.labelSmall)
                                .bold()
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.xxSmall)
                                .background(tag.contains("Icon") || tag.contains("Interactive") ? AppColor.surfaceContainerHigh : AppColor.primary)
                                .foregroundColor(tag.contains("Icon") || tag.contains("Interactive") ? AppColor.onSurface : AppColor.onPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }

                content()
            }
            .padding(AppTheme.Spacing.large)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))

            // Etiquetas inferiores
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.headlineSmall)
                    .foregroundColor(AppColor.onSurface)
                Text(subtitle)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .padding(.top, AppTheme.Spacing.xxSmall)
            .padding(.horizontal, AppTheme.Spacing.xxSmall)
        }
    }
}

#Preview("Design System Gallery") {
    DesignSystemGalleryView()
}
