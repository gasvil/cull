import SwiftUI

/// Vista de selección de modo de depuración (Paso 2 de 4).
/// Presenta las tarjetas de algoritmo (Ráfagas y Sin Rostro) con previsualización ilustrativa (`ds.md`).
public struct ModeSelectionView: View {
    @State private var viewModel: ModeSelectionViewModel
    @Environment(AppEnvironment.self) private var environment

    public init(viewModel: ModeSelectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Cabecera de la pantalla
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                        Text("¿Qué limpiamos hoy?")
                            .font(AppFont.headlineLarge)
                            .foregroundColor(AppColor.onSurface)

                        Text("Elige el algoritmo de búsqueda para tu período seleccionado.")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.onSurfaceVariant)
                    }
                    .padding(.top, AppTheme.Spacing.small)

                    // Tarjetas de Selección de Modo (FR-7, FR-9)
                    VStack(spacing: AppTheme.Spacing.medium) {
                        burstModeCard
                        noFaceModeCard
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
            }

            // Barra inferior persistente con botón de acción (FR-10)
            VStack(spacing: 0) {
                Divider()
                CullButton("Iniciar Análisis ⚡", variant: .primary, isFullWidth: true) {
                    viewModel.startAnalysis(environment: environment)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.medium)
            }
            .background(AppColor.surface)
        }
        .background(AppColor.surface)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Paso 2 de 4")
                    .font(AppFont.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
        }
    }

    // MARK: - Tarjeta de Modo: Ráfagas

    @ViewBuilder
    private var burstModeCard: some View {
        let isSelected = viewModel.selectedMode == .burst

        Button {
            viewModel.selectMode(.burst)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Fila Superior: Icono, Título, Badge y Checkmark
                HStack(alignment: .top) {
                    // Icono circular oscuro
                    ZStack {
                        Circle()
                            .fill(AppColor.primary)
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.stack.3d.down.right.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColor.onPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            Text("Ráfagas")
                                .font(AppFont.headlineSmall)
                                .foregroundColor(AppColor.onSurface)

                            Text("SMART PICK")
                                .font(AppFont.labelSmall)
                                .bold()
                                .padding(.horizontal, AppTheme.Spacing.xSmall)
                                .padding(.vertical, 2)
                                .background(AppColor.keepContainer)
                                .foregroundColor(AppColor.onKeepContainer)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    // Indicador de selección radial
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColor.primary : Color.clear)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColor.onPrimary)
                        } else {
                            Circle()
                                .strokeBorder(AppColor.outline, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                }

                // Descripción
                Text("Conserva solo la mejor toma. Agrupa capturas consecutivas y preselecciona los descartes redundantes.")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .multilineTextAlignment(.leading)

                // Previsualización ilustrativa de avatares consecutivos con insignia "TOP"
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    HStack(spacing: -8) {
                        // Avatar 1 con badge "TOP"
                        ZStack(alignment: .bottom) {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColor.keep)
                                )

                            Text("TOP")
                                .font(.system(size: 7, weight: .bold))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(AppColor.keep)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .offset(y: 4)
                        }

                        // Avatar 2
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            )

                        // Avatar 3
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            )
                    }
                    .padding(.bottom, 4)

                    Text("+2 más")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .padding(.leading, 8)

                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.xxSmall)
            }
            .padding(AppTheme.Spacing.medium)
            .background(isSelected ? AppColor.surfaceContainerLow : AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.primary : AppColor.outlineVariant, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Modo Ráfagas: Conserva solo la mejor toma")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Tarjeta de Modo: Sin Rostro

    @ViewBuilder
    private var noFaceModeCard: some View {
        let isSelected = viewModel.selectedMode == .noFace

        Button {
            viewModel.selectMode(.noFace)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Fila Superior: Icono, Título, Badge y Checkmark
                HStack(alignment: .top) {
                    // Icono circular suave
                    ZStack {
                        Circle()
                            .fill(AppColor.surfaceContainerHigh)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColor.onSurface)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            Text("Sin Rostro")
                                .font(AppFont.headlineSmall)
                                .foregroundColor(AppColor.onSurface)

                            Text("3 CATEGORÍAS")
                                .font(AppFont.labelSmall)
                                .bold()
                                .padding(.horizontal, AppTheme.Spacing.xSmall)
                                .padding(.vertical, 2)
                                .background(AppColor.accent.opacity(0.15))
                                .foregroundColor(AppColor.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    // Indicador de selección radial
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColor.primary : Color.clear)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColor.onPrimary)
                        } else {
                            Circle()
                                .strokeBorder(AppColor.outline, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                }

                // Descripción
                Text("Vouchers, capturas y fotos descartables. Encuentra documentos, tomas accidentales oscuras o fotos a validar.")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .multilineTextAlignment(.leading)

                // Previsualización ilustrativa de miniaturas de documentos, oscuras y paisaje
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    HStack(spacing: -8) {
                        // Avatar documento / recibo
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            )

                        // Avatar foto oscura / accidental
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )

                        // Avatar foto por validar / paisaje
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            )
                    }

                    Text("Utilitarias & Deficientes")
                        .font(AppFont.monoSmall)
                        .foregroundColor(AppColor.onSurfaceVariant)
                        .padding(.leading, 8)

                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.xxSmall)
            }
            .padding(AppTheme.Spacing.medium)
            .background(isSelected ? AppColor.surfaceContainerLow : AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.primary : AppColor.outlineVariant, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Modo Sin Rostro: Vouchers, capturas y fotos descartables")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("Selector de Modo") {
    NavigationStack {
        ModeSelectionView(
            viewModel: ModeSelectionViewModel(
                startDate: Date(),
                endDate: Date(),
                periodDescription: "Últimos 7 días"
            )
        )
        .environment(AppEnvironment())
    }
}
