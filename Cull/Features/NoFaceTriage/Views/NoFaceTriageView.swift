import SwiftUI

/// Vista principal para la depuración de fotos sin rostros humanos (FR-1 a FR-13).
public struct NoFaceTriageView: View {
    @State private var viewModel: NoFaceTriageViewModel

    public init(viewModel: NoFaceTriageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                ProgressView("Preparando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .selectingDate:
                dateSelectionView

            case .analyzing(let progress, let message):
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView(value: progress) {
                        Text("Analizando fotos sin personas...")
                            .font(.headline)
                    }
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(AppTheme.Spacing.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .processingDiscard:
                ProgressView("Enviando a la papelera...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let groups):
                loadedContentView(groups: groups)

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
                            await viewModel.loadAndAnalyze(forceRefresh: true)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Fotos Sin Rostros")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.prepareView()
        }
    }

    // MARK: - Loaded Content View

    @ViewBuilder
    private func loadedContentView(groups: [FacelessTriageGroup]) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    // Banner del período y ahorro recuperable
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

                        // Resumen de ahorro acumulado (FR-10)
                        if viewModel.totalRecoverableByteSize > 0 {
                            let totalFormatted = ByteCountFormatter.string(
                                fromByteCount: viewModel.totalRecoverableByteSize,
                                countStyle: .file
                            )
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                VStack(alignment: .leading) {
                                    Text("Ahorro potencial seleccionado")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(totalFormatted) (\(viewModel.totalSelectedCount) de \(viewModel.totalCandidatesCount) fotos)")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                            }
                            .padding(AppTheme.Spacing.small)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                        }
                    }
                    .padding(.horizontal)

                    // Secciones por categoría semántica (FR-4, FR-5, FR-6, FR-13)
                    ForEach(groups) { group in
                        FacelessCategorySectionView(
                            group: group,
                            photoLibraryService: viewModel.photoLibraryService,
                            onToggleSelection: { candidateId in
                                viewModel.toggleSelection(candidateId: candidateId)
                            },
                            onSelectAll: {
                                viewModel.selectAll(in: group.category)
                            },
                            onDeselectAll: {
                                viewModel.deselectAll(in: group.category)
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // Barra inferior persistente para purgar seleccionadas (FR-11)
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Divider()
                let totalFormatted = ByteCountFormatter.string(
                    fromByteCount: viewModel.totalRecoverableByteSize,
                    countStyle: .file
                )
                Button {
                    Task {
                        _ = await viewModel.confirmDiscards()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        if viewModel.totalSelectedCount > 0 {
                            Text("Purgar seleccionadas (\(viewModel.totalSelectedCount) fotos • \(totalFormatted))")
                        } else {
                            Text("Sin fotos seleccionadas")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.small)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.totalSelectedCount == 0)
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.xSmall)
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Date Selection View

    @ViewBuilder
    private var dateSelectionView: some View {
        Form {
            Section {
                Picker("Período", selection: $viewModel.filterMode) {
                    ForEach(DateFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                if viewModel.filterMode == .singleDate {
                    DatePicker(
                        "Día a analizar",
                        selection: $viewModel.selectedSingleDate,
                        displayedComponents: .date
                    )
                }

                if viewModel.filterMode == .dateRange {
                    DatePicker(
                        "Fecha de inicio",
                        selection: $viewModel.selectedStartDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Fecha de fin",
                        selection: $viewModel.selectedEndDate,
                        displayedComponents: .date
                    )
                }
            } header: {
                Text("Ventana Temporal")
            } footer: {
                Text("Selecciona una fecha para buscar fotos sin personas (vouchers, documentos, fotos borrosas y tomas intencionales).")
            }

            Section {
                Button {
                    Task {
                        await viewModel.loadAndAnalyze()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Buscar Fotos Sin Rostros", systemImage: "sparkle.magnifyingglass")
                            .bold()
                        Spacer()
                    }
                }
            }
        }
    }

    private var dateRangeDescription: String {
        let range = viewModel.resolveCurrentDateRange()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let calendar = Calendar.current
        if calendar.isDate(range.start, inSameDayAs: range.end) {
            return formatter.string(from: range.start)
        } else {
            return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
        }
    }
}
