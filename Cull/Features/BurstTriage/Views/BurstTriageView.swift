import SwiftUI

/// Vista principal de la funcionalidad de Curación y Triaje de Ráfagas.
public struct BurstTriageView: View {
    @State private var viewModel: BurstTriageViewModel

    public init(viewModel: BurstTriageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .requestingPermission:
                ProgressView("Solicitando permiso de fotos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .analyzing(let progress, let message):
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView(value: progress) {
                        Text("Analizando carrete local...")
                            .font(.headline)
                    }
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(AppTheme.Spacing.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let clusters):
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        // Banner de ahorro total
                        if viewModel.totalRecoverableByteSize > 0 {
                            let totalFormatted = ByteCountFormatter.string(
                                fromByteCount: viewModel.totalRecoverableByteSize,
                                countStyle: .file
                            )
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("Ahorro potencial total")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(totalFormatted)
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                            .padding(.horizontal)
                        }

                        // Lista de tarjetas de ráfagas
                        ForEach(clusters) { cluster in
                            BurstClusterCardView(
                                cluster: cluster,
                                onToggleKeeper: { photoId in
                                    viewModel.toggleKeeper(photoId: photoId, in: cluster.id)
                                },
                                onDiscardAll: {
                                    viewModel.discardAll(in: cluster.id)
                                },
                                onKeepAll: {
                                    viewModel.keepAll(in: cluster.id)
                                },
                                onConfirmDiscards: {
                                    Task {
                                        _ = await viewModel.confirmDiscards(for: cluster.id)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

            case .empty(let reason):
                ContentUnavailableView(
                    "Carrete al Día",
                    systemImage: "sparkles",
                    description: Text(reason)
                )

            case .error(let appError):
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(appError.localizedDescription)
                } actions: {
                    Button("Reintentar") {
                        Task {
                            await viewModel.loadAndAnalyzeClusters()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .processingDiscard:
                ProgressView("Purgando fotos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Triaje de Ráfagas")
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadAndAnalyzeClusters()
            }
        }
    }
}
