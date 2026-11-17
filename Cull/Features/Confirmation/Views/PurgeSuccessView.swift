import SwiftUI

/// Pantalla de depuración completada y celebración de espacio recuperado (FR-11 a FR-16).
public struct PurgeSuccessView: View {
    public let viewModel: ConfirmationViewModel
    public let onRestart: () -> Void

    public init(
        viewModel: ConfirmationViewModel,
        onRestart: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onRestart = onRestart
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera con Logotipo Cull y Badge de Completado (FR-12)
            headerBar
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)
                .padding(.bottom, AppTheme.Spacing.medium)

            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Hero de Celebración (FR-13)
                    celebrationHero
                        .padding(.top, AppTheme.Spacing.medium)

                    // Tarjeta de Métricas de Fotos Conservadas (FR-14)
                    metricsCard
                        .padding(.horizontal, AppTheme.Spacing.medium)

                    // Callout de Sugerencia Semanal (FR-15)
                    tipCalloutCard
                        .padding(.horizontal, AppTheme.Spacing.medium)
                }
                .padding(.bottom, 100) // Espacio para el botón inferior
            }

            // Botón principal inferior de reinicio (FR-16)
            bottomActionButton
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.small)
        }
        .background(AppColor.surface.ignoresSafeArea())
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Icono de la marca Cull
            HStack(spacing: 8) {
                Circle()
                    .fill(AppColor.keep)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("C")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )

                Text("Cull")
                    .font(AppFont.headlineLarge)
                    .foregroundColor(AppColor.onSurface)
            }

            Spacer()

            // Badge pill "Completado"
            Text("Completado")
                .font(AppFont.monoSmall)
                .foregroundColor(AppColor.keep)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColor.keepContainer.opacity(0.4))
                .clipShape(Capsule())
        }
        .frame(minHeight: 44)
    }

    // MARK: - Celebration Hero

    private var celebrationHero: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Anillo doble con checkmark verde
            ZStack {
                Circle()
                    .fill(AppColor.keepContainer.opacity(0.5))
                    .frame(width: 96, height: 96)

                Circle()
                    .strokeBorder(AppColor.keep, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColor.keep)
            }
            .padding(.bottom, AppTheme.Spacing.xSmall)

            // Etiqueta ¡BIBLIOTECA OPTIMIZADA!
            Text("¡BIBLIOTECA OPTIMIZADA!")
                .font(AppFont.monoSmall)
                .bold()
                .foregroundColor(AppColor.keep)
                .tracking(0.5)

            // Titular display grande: +X.X MB libres
            Text("+\(viewModel.formattedRecoverableSpace) libres")
                .font(AppFont.displayLarge)
                .bold()
                .foregroundColor(AppColor.onSurface)

            // Subtítulo de fotos eliminadas
            Text("Se eliminaron exitosamente \(viewModel.markedPhotoIds.count) fotos \(viewModel.modeSubtitleText) de tu almacenamiento.")
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
        }
    }

    // MARK: - Metrics Card

    private var metricsCard: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Fila 1: Estado de fotos conservadas
            HStack {
                Text("Estado de fotos conservadas")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Calidad 100%")
                        .font(AppFont.monoSmall)
                        .bold()
                }
                .foregroundColor(AppColor.keep)
            }

            // Fila 2: Subtítulos de memoria y barra de progreso
            HStack {
                Text("Memoria del carrete")
                    .font(AppFont.monoSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                Text("Espacio recuperado")
                    .font(AppFont.monoSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
            }
            .padding(.top, 4)

            // Barra visual de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.surfaceContainerHigh)
                        .frame(height: 8)

                    Capsule()
                        .fill(AppColor.keep)
                        .frame(width: max(geometry.size.width * 0.45, 24), height: 8)
                }
            }
            .frame(height: 8)

            Divider()
                .padding(.vertical, AppTheme.Spacing.xxSmall)

            // Fila 3: Disponibilidad en papelera
            HStack {
                Text("Disponible en papelera:")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                Text("30 días")
                    .font(AppFont.monoSmall)
                    .bold()
                    .foregroundColor(AppColor.onSurface)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColor.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
        )
    }

    // MARK: - Tip Callout Card

    private var tipCalloutCard: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundColor(AppColor.accent)
                .padding(.top, 2)

            Text(viewModel.tipText)
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .lineSpacing(2)

            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColor.surfaceContainerLow.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .strokeBorder(AppColor.outlineVariant.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Bottom Action Button

    private var bottomActionButton: some View {
        Button {
            onRestart()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                Text("Listo • Nueva depuración")
                    .font(AppFont.headlineSmall)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColor.primary)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Finalizar depuración y volver al inicio")
    }
}
