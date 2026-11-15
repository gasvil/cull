import SwiftUI

/// Componente que renderiza una tarjeta de lote de ráfaga o fotos similares.
/// Permite al usuario alternar tomas conservadas, ejecutar 'Eliminar todo', 'Mantener todo' o purgar.
public struct BurstClusterCardView: View {
    public let cluster: BurstCluster
    public let onToggleKeeper: (String) -> Void
    public let onDiscardAll: () -> Void
    public let onKeepAll: () -> Void
    public let onConfirmDiscards: () -> Void

    public init(
        cluster: BurstCluster,
        onToggleKeeper: @escaping (String) -> Void,
        onDiscardAll: @escaping () -> Void,
        onKeepAll: @escaping () -> Void,
        onConfirmDiscards: @escaping () -> Void
    ) {
        self.cluster = cluster
        self.onToggleKeeper = onToggleKeeper
        self.onDiscardAll = onDiscardAll
        self.onKeepAll = onKeepAll
        self.onConfirmDiscards = onConfirmDiscards
    }

    private var formattedRecoverableSpace: String {
        ByteCountFormatter.string(fromByteCount: cluster.recoverableByteSize, countStyle: .file)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Cabecera: Cantidad de fotos, espacio a liberar y acciones rápidas
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text("\(cluster.items.count) fotos en serie")
                        .font(.headline)
                    if cluster.recoverableByteSize > 0 {
                        Text("Recupera \(formattedRecoverableSpace)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .bold()
                    } else {
                        Text("Todas las fotos conservadas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Acciones Rápidas (FR-10, FR-11)
                Menu {
                    Button(role: .destructive, action: onDiscardAll) {
                        Label("Eliminar todo el lote", systemImage: "trash.fill")
                    }
                    Button(action: onKeepAll) {
                        Label("Mantener todo el lote", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }

            // Carrusel horizontal de miniaturas con estados
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(cluster.items) { candidate in
                        let isKeeper = cluster.keeperIds.contains(candidate.id)
                        let isDiscard = cluster.discardIds.contains(candidate.id)

                        Button {
                            onToggleKeeper(candidate.id)
                        } label: {
                            VStack(spacing: AppTheme.Spacing.xxSmall) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 130)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.secondary)
                                        }

                                    // Badge de Favorita
                                    if candidate.asset.isFavorite {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                            .padding(4)
                                    }
                                }

                                // Indicador de estado y calidad
                                if isKeeper {
                                    Label("Conservar", systemImage: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundColor(.green)
                                } else if isDiscard {
                                    Label("Descartar", systemImage: "trash")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                } else {
                                    Text("Omitida")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                if let score = candidate.assessment?.compositeScore {
                                    Text(String(format: "Score: %.0f%%", score * 100))
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xxSmall)
            }

            // Botón de confirmación para este lote
            if !cluster.discardIds.isEmpty {
                Button(action: onConfirmDiscards) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                        Text("Purgar \(cluster.discardIds.count) fotos (\(formattedRecoverableSpace))")
                            .bold()
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
