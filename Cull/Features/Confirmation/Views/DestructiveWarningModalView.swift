import SwiftUI

/// Modal de advertencia destructiva antes de invocar la eliminación en PhotoKit (FR-8, FR-9).
public struct DestructiveWarningModalView: View {
    public let count: Int
    public let formattedSpace: String
    public let onConfirm: () -> Void
    public let onCancel: () -> Void

    public init(
        count: Int,
        formattedSpace: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.count = count
        self.formattedSpace = formattedSpace
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            // Fondo atenuado oscuro
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(spacing: AppTheme.Spacing.small) {
                // Tarjeta principal con icono, mensaje de confirmación y acción destructiva
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Icono de advertencia en contenedor circular suave
                    ZStack {
                        Circle()
                            .fill(AppColor.cullContainer.opacity(0.5))
                            .frame(width: 48, height: 48)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppColor.cull)
                    }
                    .padding(.top, AppTheme.Spacing.xSmall)

                    // Título de confirmación
                    Text("¿Eliminar \(count) \(count == 1 ? "foto seleccionada" : "fotos seleccionadas")?")
                        .font(AppFont.headlineSmall)
                        .bold()
                        .foregroundColor(AppColor.onSurface)
                        .multilineTextAlignment(.center)

                    // Descripción del espacio y tiempo de recuperación en papelera
                    VStack(spacing: 4) {
                        Text("Esta acción liberará ")
                            .foregroundColor(AppColor.onSurfaceVariant)
                        + Text("\(formattedSpace)")
                            .bold()
                            .foregroundColor(AppColor.onSurface)
                        + Text(" de almacenamiento.")
                            .foregroundColor(AppColor.onSurfaceVariant)

                        Text("Las fotos podrán recuperarse en el álbum \"Eliminado recientemente\" durante 30 días.")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .font(AppFont.bodyMedium)
                    .padding(.horizontal, AppTheme.Spacing.small)

                    Divider()
                        .padding(.top, AppTheme.Spacing.xxSmall)

                    // Botón destructivo "Eliminar definitivamente"
                    Button {
                        onConfirm()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                            Text("Eliminar definitivamente")
                                .font(AppFont.labelLarge)
                                .bold()
                        }
                        .foregroundColor(AppColor.cull)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Confirmar y eliminar definitivamente \(count) fotos")
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 20, y: 8)

                // Botón independiente "Cancelar"
                Button {
                    onCancel()
                } label: {
                    Text("Cancelar")
                        .font(AppFont.labelLarge)
                        .bold()
                        .foregroundColor(AppColor.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar eliminación")
            }
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
