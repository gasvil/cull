import SwiftUI

/// Vista de sección para una categoría semántica de fotos sin rostros (FR-4 a FR-9, FR-13).
public struct FacelessCategorySectionView: View {
    public let group: FacelessTriageGroup
    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let onToggleSelection: (String) -> Void
    public let onSelectAll: () -> Void
    public let onDeselectAll: () -> Void

    public init(
        group: FacelessTriageGroup,
        photoLibraryService: PhotoLibraryServiceProtocol,
        onToggleSelection: @escaping (String) -> Void,
        onSelectAll: @escaping () -> Void,
        onDeselectAll: @escaping () -> Void
    ) {
        self.group = group
        self.photoLibraryService = photoLibraryService
        self.onToggleSelection = onToggleSelection
        self.onSelectAll = onSelectAll
        self.onDeselectAll = onDeselectAll
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: AppTheme.Spacing.small)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Cabecera de Categoría
            HStack(alignment: .center) {
                Label {
                    Text(group.category.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: group.category.systemImage)
                        .foregroundColor(group.category.badgeColor)
                }

                // FR-13: Conteo explícito (ej. "0 fotos", "3 fotos")
                Text("\(group.totalCount) \(group.totalCount == 1 ? "foto" : "fotos")")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, 2)
                    .background(group.totalCount > 0 ? group.category.badgeColor.opacity(0.15) : Color.secondary.opacity(0.15))
                    .foregroundColor(group.totalCount > 0 ? group.category.badgeColor : .secondary)
                    .clipShape(Capsule())

                Spacer()

                // Acciones masivas por categoría (FR-9)
                HStack(spacing: AppTheme.Spacing.small) {
                    Button("Todas") {
                        onSelectAll()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(group.totalCount == 0 || group.allSelected)

                    Button("Ninguna") {
                        onDeselectAll()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(group.totalCount == 0 || group.noneSelected)
                }
            }

            Text(group.category.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            // Contenido: Cuadrícula o contenedor vacío explícito (FR-13, EC-4)
            if group.totalCount == 0 {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.secondary)
                    Text("0 fotos encontradas en esta categoría")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(AppTheme.Spacing.small)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            } else {
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                    ForEach(group.candidates) { candidate in
                        candidateThumbnailCard(candidate)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }

    @ViewBuilder
    private func candidateThumbnailCard(_ candidate: FacelessPhotoCandidate) -> some View {
        Button {
            onToggleSelection(candidate.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                PhotoThumbnailView(
                    assetId: candidate.id,
                    targetSize: CGSize(width: 200, height: 260),
                    photoLibraryService: photoLibraryService
                )
                .frame(width: 100, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                // Indicador de selección visual (FR-8)
                ZStack {
                    Circle()
                        .fill(candidate.isSelected ? Color.red : Color.black.opacity(0.4))
                        .frame(width: 26, height: 26)

                    Image(systemName: candidate.isSelected ? "trash.fill" : "circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(6)
                .shadow(radius: 2)

                // Indicador de peso de la foto en la parte inferior
                VStack {
                    Spacer()
                    HStack {
                        let formattedSize = ByteCountFormatter.string(
                            fromByteCount: candidate.asset.byteSize,
                            countStyle: .file
                        )
                        Text(formattedSize)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(candidate.isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(candidate.isSelected ? "Foto seleccionada para descarte" : "Foto conservada")
        .accessibilityHint("Toca dos veces para cambiar la selección")
    }
}
