import SwiftUI

/// Vista principal de la funcionalidad de Curación y Triaje de Ráfagas (Paso 3 de 4).
public struct BurstTriageView: View {
    @State private var viewModel: BurstTriageViewModel
    @Environment(AppRouter.self) private var router

    public init(viewModel: BurstTriageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Barra superior personalizada con botón < Modo y Pill de estado (FR-1, FR-2)
            headerBar
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)
                .padding(.bottom, AppTheme.Spacing.xSmall)

            Divider()
                .opacity(0.6)

            ZStack(alignment: .bottom) {
                contentForState

                // Botón flotante inferior de confirmación (FR-12, FR-13)
                if case .loaded = viewModel.state {
                    floatingBottomBar
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(AppColor.surfaceContainerLow.opacity(0.3).ignoresSafeArea())
        .fullScreenCover(item: $viewModel.previewCandidate) { candidate in
            PhotoDetailModalView(
                candidate: candidate,
                photoLibraryService: viewModel.photoLibraryService,
                onDismiss: {
                    viewModel.previewCandidate = nil
                }
            )
        }
        .task {
            viewModel.prepareView()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(alignment: .center) {
            Button {
                router.navigateBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Modo")
                        .font(AppFont.bodyLarge)
                }
                .foregroundColor(AppColor.accent)
            }
            .accessibilityLabel("Volver a selección de modo")

            Spacer()

            // Pill de estado con dot azul y conteo de fotos procesadas (FR-2)
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColor.accent)
                    .frame(width: 7, height: 7)

                Text("Ráfagas · \(viewModel.totalPhotosCount) fotos")
                    .font(AppFont.monoSmall)
                    .foregroundColor(AppColor.onSurface)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColor.surfaceContainerLow)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
            )
            .accessibilityLabel("Modo Ráfagas, \(viewModel.totalPhotosCount) fotos procesadas")
        }
        .frame(minHeight: 44)
    }

    // MARK: - State Handling

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.state {
        case .idle, .requestingPermission:
            ProgressView("Solicitando permiso de fotos...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .selectingDate:
            dateSelectionView

        case .analyzing(let progress, let message):
            VStack(spacing: AppTheme.Spacing.medium) {
                ProgressView(value: progress) {
                    Text("Analizando ráfagas del período...")
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onSurface)
                }
                .tint(AppColor.accent)

                Text(message)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .padding(AppTheme.Spacing.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let clusters):
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(Array(clusters.enumerated()), id: \.element.id) { index, cluster in
                        BurstClusterCardView(
                            clusterIndex: index + 1,
                            cluster: cluster,
                            photoLibraryService: viewModel.photoLibraryService,
                            onSelectWinner: { photoId in
                                viewModel.setPrimaryWinner(photoId: photoId, in: cluster.id)
                            },
                            onDiscardAll: {
                                viewModel.discardAll(in: cluster.id)
                            },
                            onKeepAll: {
                                viewModel.keepAll(in: cluster.id)
                            },
                            onPreview: { candidate in
                                viewModel.previewCandidate = candidate
                            }
                        )
                        .padding(.horizontal, AppTheme.Spacing.medium)
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
                .padding(.bottom, 96) // Margen para el botón flotante
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

    // MARK: - Floating Bottom Bar

    private var floatingBottomBar: some View {
        VStack(spacing: 0) {
            Spacer()

            Button {
                router.navigate(
                    to: .reviewConfirmation(
                        markedPhotoIds: viewModel.allMarkedDiscardIds,
                        totalByteSize: viewModel.totalRecoverableByteSize
                    )
                )
            } label: {
                HStack(spacing: 8) {
                    Text("Continuar (\(viewModel.totalMarkedDiscardsCount) fotos marcadas)")
                        .font(AppFont.headlineSmall)
                        .foregroundColor(AppColor.onPrimary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColor.onPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColor.primary)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.small)
        }
    }

    // MARK: - Date Selection Fallback

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
}
