import SwiftUI

/// Componente que renderiza una tarjeta de lote de ráfaga o fotos similares.
/// Muestra un visor prominente de la foto ganadora y un carrusel inferior con todas las tomas (FR-3, FR-8).
public struct BurstClusterCardView: View {
    public let clusterIndex: Int
    public let cluster: BurstCluster
    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let onSelectWinner: (String) -> Void
    public let onDiscardAll: () -> Void
    public let onKeepAll: () -> Void
    public let onPreview: (PhotoCandidate) -> Void

    public init(
        clusterIndex: Int = 1,
        cluster: BurstCluster,
        photoLibraryService: PhotoLibraryServiceProtocol,
        onSelectWinner: @escaping (String) -> Void,
        onDiscardAll: @escaping () -> Void,
        onKeepAll: @escaping () -> Void,
        onPreview: @escaping (PhotoCandidate) -> Void
    ) {
        self.clusterIndex = clusterIndex
        self.cluster = cluster
        self.photoLibraryService = photoLibraryService
        self.onSelectWinner = onSelectWinner
        self.onDiscardAll = onDiscardAll
        self.onKeepAll = onKeepAll
        self.onPreview = onPreview
    }

    private var formattedRecoverableSpace: String {
        ByteCountFormatter.string(fromByteCount: cluster.recoverableByteSize, countStyle: .file)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Cabecera: Dot identificador verde, título cronológico y menú contextual (FR-3, FR-4)
            HStack(alignment: .center, spacing: AppTheme.Spacing.small) {
                Circle()
                    .fill(AppColor.keep)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ráfaga #\(clusterIndex) · \(cluster.formattedTime)")
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onSurface)

                    Text("\(cluster.formattedDate) · \(cluster.items.count) tomas")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                }

                Spacer()

                // Menú contextual ⋮ (FR-4)
                Menu {
                    Button {
                        onKeepAll()
                    } label: {
                        Label("Conservar todo", systemImage: "checkmark.circle")
                    }

                    Button(role: .destructive) {
                        onDiscardAll()
                    } label: {
                        Label("Eliminar todo", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Opciones de ráfaga #\(clusterIndex)")
            }

            // Visor Hero de la foto Ganadora (FR-5, FR-6)
            if let heroCandidate = cluster.primaryWinner {
                ZStack(alignment: .bottom) {
                    PhotoThumbnailView(
                        assetId: heroCandidate.id,
                        targetSize: CGSize(width: 1024, height: 1024),
                        cornerRadius: AppTheme.CornerRadius.medium,
                        photoLibraryService: photoLibraryService
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
                    .contentShape(Rectangle())
                    .onLongPressGesture {
                        onPreview(heroCandidate)
                    }

                    // Insignias sobre la foto ganadora (FR-6)
                    HStack {
                        if cluster.keeperIds.contains(heroCandidate.id) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("Ganadora (Conservar)")
                                    .font(AppFont.labelSmall)
                                    .bold()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.keep)
                            .clipShape(Capsule())
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 10))
                            Text("Mantén presionado")
                                .font(AppFont.labelSmall)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                    }
                    .padding(AppTheme.Spacing.small)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Foto ganadora de la ráfaga, mantén presionado para ampliar")
            }

            // Fila de resumen: tomas alternativas y espacio liberable (FR-7)
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColor.cull)
                        .frame(width: 6, height: 6)
                    Text("\(cluster.discardIds.count) tomas alternativas")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                }

                Spacer()

                if cluster.recoverableByteSize > 0 {
                    Text("Liberará ~\(formattedRecoverableSpace)")
                        .font(AppFont.monoSmall)
                        .bold()
                        .foregroundColor(AppColor.cull)
                } else {
                    Text("0 B a liberar")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.keep)
                }
            }
            .padding(.top, AppTheme.Spacing.xxSmall)

            // Carrusel horizontal de miniaturas (FR-8, FR-9, FR-10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(cluster.items) { candidate in
                        let isKeeper = cluster.keeperIds.contains(candidate.id)
                        let isWinner = cluster.primaryWinner?.id == candidate.id

                        Button {
                            onSelectWinner(candidate.id)
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                PhotoThumbnailView(
                                    assetId: candidate.id,
                                    targetSize: CGSize(width: 250, height: 250),
                                    cornerRadius: AppTheme.CornerRadius.small,
                                    photoLibraryService: photoLibraryService
                                )
                                .frame(width: 66, height: 66)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                                        .strokeBorder(isWinner ? AppColor.keep : Color.clear, lineWidth: 2)
                                )

                                // Indicador de estado (verde para keeper, rojo con checkmark para descarte - FR-9)
                                if isKeeper {
                                    Circle()
                                        .fill(AppColor.keep)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: -4, y: 4)
                                } else {
                                    Circle()
                                        .fill(AppColor.cull)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: -4, y: 4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.4)
                                .onEnded { _ in
                                    onPreview(candidate)
                                }
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(isKeeper ? "Toma conservada" : "Toma marcada para eliminar")
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xxSmall)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
        )
    }
}
