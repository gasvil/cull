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

            case .selectingDate:
                dateSelectionView

            case .analyzing(let progress, let message):
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView(value: progress) {
                        Text("Analizando fotos del período...")
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
                        // Banner de información del filtro de fecha y ahorro total
                        VStack(spacing: AppTheme.Spacing.small) {
                            HStack {
                                Label(dateRangeDescription, systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Cambiar fecha") {
                                    viewModel.changeDateFilter()
                                }
                                .font(.subheadline)
                            }

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
                                        Text("Ahorro potencial en esta fecha")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(totalFormatted)
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                }
                                .padding(AppTheme.Spacing.small)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                            }
                        }
                        .padding(.horizontal)

                        // Lista de tarjetas de ráfagas
                        ForEach(clusters) { cluster in
                            BurstClusterCardView(
                                cluster: cluster,
                                photoLibraryService: viewModel.photoLibraryService,
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
                ContentUnavailableView {
                    Label("Carrete al Día", systemImage: "sparkles")
                } description: {
                    Text(reason)
                } actions: {
                    Button("Cambiar período") {
                        viewModel.changeDateFilter()
                    }
                    .buttonStyle(.borderedProminent)
                }

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
        .toolbar {
            if case .loaded = viewModel.state {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.loadAndAnalyzeClusters(forceRefresh: true)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            viewModel.prepareView()
        }
    }

    private var dateSelectionView: some View {
        Form {
            Section {
                Picker("Período", selection: $viewModel.filterMode) {
                    ForEach(DateFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Selecciona el período a analizar")
            }

            if viewModel.filterMode == .singleDate {
                Section("Día a analizar") {
                    DatePicker(
                        "Fecha",
                        selection: $viewModel.selectedSingleDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
            } else if viewModel.filterMode == .dateRange {
                Section("Rango de fechas") {
                    DatePicker(
                        "Desde",
                        selection: $viewModel.selectedStartDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Hasta",
                        selection: $viewModel.selectedEndDate,
                        displayedComponents: .date
                    )
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.loadAndAnalyzeClusters()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                        Text("Buscar ráfagas en esta fecha")
                            .bold()
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var dateRangeDescription: String {
        let range = viewModel.resolveCurrentDateRange()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        switch viewModel.filterMode {
        case .today:
            return "Hoy (\(formatter.string(from: range.start)))"
        case .yesterday:
            return "Ayer (\(formatter.string(from: range.start)))"
        case .singleDate:
            return formatter.string(from: range.start)
        case .last7Days, .dateRange:
            return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
        }
    }
}
