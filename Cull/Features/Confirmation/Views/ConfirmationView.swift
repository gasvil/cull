import SwiftUI

/// Vista principal del Paso 4 de 4: Revisión Final y Confirmación de Depuración (FR-1 a FR-16).
public struct ConfirmationView: View {
    @State private var viewModel: ConfirmationViewModel
    @Environment(AppRouter.self) private var router

    public init(viewModel: ConfirmationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.state == .completed {
                // Fase 3: Pantalla de Depuración Completada (FR-11 a FR-16)
                PurgeSuccessView(viewModel: viewModel) {
                    router.popToRoot()
                }
            } else {
                // Fase 1 y 2: Pantalla de Confirmación y Modal de Advertencia
                confirmationMainContent
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Main Content

    private var confirmationMainContent: some View {
        ZStack {
            VStack(spacing: 0) {
                // Cabecera superior con botón < Revisar y etiqueta "Confirmación" (FR-1)
                headerBar
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.top, AppTheme.Spacing.small)
                    .padding(.bottom, AppTheme.Spacing.xSmall)

                Divider()
                    .opacity(0.6)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.large) {
                        // Icono Hero de papelera en contenedor suave
                        heroIconContainer
                            .padding(.top, AppTheme.Spacing.large)

                        // Titular y Subtítulo de Espacio Recuperable (FR-2, FR-3)
                        impactSummarySection
                            .padding(.horizontal, AppTheme.Spacing.medium)

                        // Tarjeta de Metadatos de la Depuración (FR-4)
                        metadataCard
                            .padding(.horizontal, AppTheme.Spacing.medium)

                        // Insignia de Privacidad en Dispositivo (FR-5)
                        privacyBadge
                    }
                    .padding(.bottom, 100) // Espacio para el botón flotante
                }

                // Botón inferior "Depurar ahora" (FR-6, FR-7)
                bottomPurgeButton
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.small)
            }
            .background(AppColor.surface.ignoresSafeArea())

            // Fase 2: Modal de Advertencia Destructiva (FR-8, FR-9, FR-10)
            if viewModel.state == .presentingWarningModal {
                DestructiveWarningModalView(
                    count: viewModel.markedPhotoIds.count,
                    formattedSpace: viewModel.formattedRecoverableSpace,
                    onConfirm: {
                        Task {
                            _ = await viewModel.confirmPurge()
                        }
                    },
                    onCancel: {
                        viewModel.dismissWarningModal()
                    }
                )
            }

            // Indicador de procesamiento si se está ejecutando el borrado
            if viewModel.state == .purging {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: AppTheme.Spacing.small) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Moviendo a la papelera...")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(.white)
                    }
                    .padding(AppTheme.Spacing.large)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
                }
            }
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
                    Text("Revisar")
                        .font(AppFont.bodyLarge)
                }
                .foregroundColor(AppColor.accent)
            }
            .accessibilityLabel("Volver a revisar fotos")

            Spacer()

            Text("Confirmación")
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
        }
        .frame(minHeight: 44)
    }

    // MARK: - Hero Icon Container

    private var heroIconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.cullContainer.opacity(0.45))
                .frame(width: 80, height: 80)

            Image(systemName: "trash")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(AppColor.cull)
        }
    }

    // MARK: - Impact Summary Section

    private var impactSummarySection: some View {
        VStack(spacing: 8) {
            Text("ESPACIO RECUPERABLE")
                .font(AppFont.monoSmall)
                .bold()
                .foregroundColor(AppColor.cull)
                .tracking(0.5)

            Text("Liberarás \(viewModel.formattedRecoverableSpace)")
                .font(AppFont.displayLarge)
                .bold()
                .foregroundColor(AppColor.onSurface)
                .multilineTextAlignment(.center)

            Text("\(viewModel.markedPhotoIds.count) fotos se eliminarán de este dispositivo y se moverán al álbum \"Eliminado recientemente\" de Fotos.")
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Período analizado
            HStack {
                Text("Período analizado:")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                Text(viewModel.periodDescription)
                    .font(AppFont.bodyMedium)
                    .bold()
                    .foregroundColor(AppColor.onSurface)
            }

            // Tipo de depuración
            HStack {
                Text("Tipo de depuración:")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                Text(viewModel.triageTypeDescription)
                    .font(AppFont.bodyMedium)
                    .bold()
                    .foregroundColor(AppColor.onSurface)
            }

            Divider()
                .padding(.vertical, 2)

            // Destino
            HStack {
                Text("Destino:")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.onSurfaceVariant)

                Spacer()

                Text("Papelera del sistema")
                    .font(AppFont.monoSmall)
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

    // MARK: - Privacy Badge

    private var privacyBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(AppColor.onSurfaceVariant)

            Text("Procesado 100% en el dispositivo")
                .font(AppFont.monoSmall)
                .foregroundColor(AppColor.onSurfaceVariant)
        }
    }

    // MARK: - Bottom Purge Button

    private var bottomPurgeButton: some View {
        Button {
            viewModel.requestPurge()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                Text("Depurar ahora")
                    .font(AppFont.headlineSmall)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(viewModel.isPurgeDisabled ? AppColor.cull.opacity(0.4) : AppColor.cull)
            .clipShape(Capsule())
            .shadow(
                color: viewModel.isPurgeDisabled ? Color.clear : AppColor.cull.opacity(0.25),
                radius: 10,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isPurgeDisabled)
        .accessibilityLabel("Depurar ahora \(viewModel.markedPhotoIds.count) fotos seleccionadas")
    }
}
