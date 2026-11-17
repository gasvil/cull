import SwiftUI

/// Vista principal para la depuración de fotos sin rostros humanos (Paso 3 de 4).
/// Organizada mediante pestañas exclusivas por categoría y cuadrícula de 3 columnas (FR-1 a FR-16).
public struct NoFaceTriageView: View {
    @State private var viewModel: NoFaceTriageViewModel
    @Environment(AppRouter.self) private var router

    public init(viewModel: NoFaceTriageViewModel) {
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

                // Botón flotante inferior de confirmación (FR-15, FR-16)
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

            // Pill de estado con dot azul y conteo consolidado (FR-2)
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColor.accent)
                    .frame(width: 7, height: 7)

                Text("Sin Rostro · \(viewModel.totalCandidatesCount) fotos")
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
            .accessibilityLabel("Modo Sin Rostro, \(viewModel.totalCandidatesCount) fotos procesadas")
        }
        .frame(minHeight: 44)
    }

    // MARK: - State Handling

    @ViewBuilder
    private var contentForState: some View {
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

    // MARK: - Loaded Content View

    @ViewBuilder
    private func loadedContentView(groups: [FacelessTriageGroup]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Título y Subtítulo de la Pantalla (FR-3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Depuración Sin Rostro")
                        .font(AppFont.headlineLarge)
                        .foregroundColor(AppColor.onSurface)

                    Text("Las fotos con alta prioridad vienen preseleccionadas. Las de prioridad media esperan tu confirmación.")
                        .font(AppFont.bodyMedium)
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .lineSpacing(2)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)

                // Selector de Pestañas de Categoría (FR-4, FR-5)
                categoryTabsView(groups: groups)
                    .padding(.horizontal, AppTheme.Spacing.medium)

                // Tarjeta de la categoría activa (FR-6, FR-7)
                if let activeGroup = viewModel.group(for: viewModel.selectedCategory) {
                    FacelessCategoryHeaderCardView(
                        group: activeGroup,
                        onToggleBulkSelection: {
                            viewModel.toggleCategoryBulkSelection(for: viewModel.selectedCategory)
                        }
                    )
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    // Cuadrícula de 3 columnas (FR-8, FR-10, FR-11)
                    if activeGroup.candidates.isEmpty {
                        VStack(spacing: AppTheme.Spacing.small) {
                            Text("No se encontraron fotos en esta categoría.")
                                .font(AppFont.bodyMedium)
                                .foregroundColor(AppColor.onSurfaceVariant)
                                .padding(.vertical, AppTheme.Spacing.large)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        let columns = Array(
                            repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small),
                            count: 3
                        )

                        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                            ForEach(activeGroup.candidates) { candidate in
                                FacelessPhotoCellView(
                                    candidate: candidate,
                                    photoLibraryService: viewModel.photoLibraryService,
                                    onToggle: {
                                        viewModel.toggleSelection(candidateId: candidate.id)
                                    },
                                    onPreview: {
                                        viewModel.previewCandidate = candidate.asPhotoCandidate
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                    }
                }
            }
            .padding(.bottom, 100) // Espacio para el botón flotante
        }
    }

    // MARK: - Category Tabs View

    private func categoryTabsView(groups: [FacelessTriageGroup]) -> some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            ForEach(FacelessCategory.allCases) { category in
                let isSelected = viewModel.selectedCategory == category
                let count = viewModel.group(for: category)?.totalCount ?? 0

                Button {
                    withAnimation(AppMotion.stateChange) {
                        viewModel.selectCategory(category)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(category.title)
                            .font(AppFont.labelMedium)
                            .foregroundColor(isSelected ? AppColor.onSurface : AppColor.onSurfaceVariant)

                        // Badge numérico con estilo según prioridad (FR-4)
                        Circle()
                            .fill(category.isHighPriority ? AppColor.cull : AppColor.surfaceContainerHigh)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(category.isHighPriority ? .white : AppColor.onSurfaceVariant)
                            )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppColor.surface : AppColor.surfaceContainerLow)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? AppColor.outline : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Categoría \(category.title), \(count) fotos\(isSelected ? ", seleccionada" : "")")
            }
        }
    }

    // MARK: - Floating Bottom Bar

    private var floatingBottomBar: some View {
        VStack(spacing: 0) {
            Spacer()

            Button {
                router.navigate(
                    to: .reviewConfirmation(
                        markedPhotoIds: viewModel.allSelectedCandidateIds,
                        totalByteSize: viewModel.totalRecoverableByteSize
                    )
                )
            } label: {
                HStack(spacing: 8) {
                    Text("Continuar (\(viewModel.totalSelectedCount) fotos marcadas)")
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

    // MARK: - Fallback Date Selection

    private var dateSelectionView: some View {
        Form {
            Section("Período") {
                Picker("Período", selection: $viewModel.filterMode) {
                    ForEach(DateFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button {
                    Task {
                        await viewModel.loadAndAnalyze()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                        Text("Iniciar depuración")
                            .bold()
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
