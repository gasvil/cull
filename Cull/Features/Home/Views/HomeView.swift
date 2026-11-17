import SwiftUI

/// Vista principal de la aplicación: Selección de Período Temporal (Paso 1).
/// Diseñada con el sistema de diseño Cull (`ds.md`) conforme al mockup de referencia.
public struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Cabecera superior con Branding y Botón de Biblioteca
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CULL STUDIO")
                                .font(AppFont.monoSmall)
                                .foregroundColor(AppColor.onSurfaceVariant)
                                .tracking(1.0)

                            Text("Cull")
                                .font(AppFont.headlineLarge)
                                .foregroundColor(AppColor.onSurface)
                        }

                        Spacer()

                        CullIconButton(
                            systemImage: "photo.on.rectangle",
                            accessibilityLabel: "Biblioteca de fotos",
                            tint: AppColor.onSurface,
                            backgroundColor: AppColor.surfaceContainerLow
                        ) {}
                    }
                    .padding(.top, AppTheme.Spacing.small)

                    // Bloque de Pregunta y Explicación
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                        Text("¿Qué período deseas analizar?")
                            .font(AppFont.headlineSmall)
                            .foregroundColor(AppColor.onSurface)

                        Text("Revisaremos tu biblioteca para encontrar tomas redundantes o fotos descartables.")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.onSurfaceVariant)
                    }

                    // Lista de Opciones de Período (FR-1, FR-2)
                    VStack(spacing: AppTheme.Spacing.small) {
                        ForEach(PeriodOption.allCases) { option in
                            periodOptionRow(option)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
            }

            // Botón Inferior Persistente (FR-5)
            VStack(spacing: 0) {
                Divider()
                CullButton("Siguiente →", variant: .primary, isFullWidth: true) {
                    let range = viewModel.resolveCurrentDateRange()
                    router.navigate(
                        to: .modeSelection(
                            startDate: range.start,
                            endDate: range.end,
                            periodDescription: viewModel.selectedPeriod.title
                        )
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.medium)
            }
            .background(AppColor.surface)
        }
        .background(AppColor.surface)
        .navigationBarHidden(true)
        .task {
            viewModel.loadInitialData()
        }
    }

    // MARK: - Fila de Opción de Período

    @ViewBuilder
    private func periodOptionRow(_ option: PeriodOption) -> some View {
        let isSelected = viewModel.selectedPeriod == option

        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Button {
                viewModel.selectPeriod(option)
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    // Icono contenedor circular/cuadrado suave
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColor.primary : AppColor.surfaceContainerHigh.opacity(0.5))
                            .frame(width: 44, height: 44)

                        Image(systemName: option.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? AppColor.onPrimary : AppColor.onSurface)
                    }

                    // Título y Subtítulo dinámico con conteo
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title)
                            .font(AppFont.headlineSmall)
                            .foregroundColor(AppColor.onSurface)

                        Text(viewModel.subtitle(for: option))
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.onSurfaceVariant)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Indicador Radial de Selección
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? AppColor.primary : AppColor.outline, lineWidth: 1.5)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(AppColor.primary)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Controles expandibles cuando se selecciona 'Personalizado' (FR-3)
            if option == .custom && isSelected {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xxSmall)

                    Picker("Modo de fecha", selection: $viewModel.customDateMode) {
                        ForEach(CustomDateMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.customDateMode) { _, _ in
                        viewModel.refreshPhotoCount()
                    }

                    if viewModel.customDateMode == .singleDate {
                        DatePicker(
                            "Día específico",
                            selection: $viewModel.selectedSingleDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: viewModel.selectedSingleDate) { _, _ in
                            viewModel.refreshPhotoCount()
                        }
                    } else {
                        DatePicker(
                            "Fecha inicio",
                            selection: $viewModel.selectedStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: viewModel.selectedStartDate) { _, _ in
                            viewModel.refreshPhotoCount()
                        }

                        DatePicker(
                            "Fecha fin",
                            selection: $viewModel.selectedEndDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: viewModel.selectedEndDate) { _, _ in
                            viewModel.refreshPhotoCount()
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.xxSmall)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(isSelected ? AppColor.surfaceContainerLow : AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .strokeBorder(isSelected ? AppColor.primary : AppColor.outlineVariant, lineWidth: isSelected ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(option.title), \(viewModel.subtitle(for: option))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("Home View") {
    NavigationStack {
        HomeView()
            .environment(AppRouter())
    }
}
