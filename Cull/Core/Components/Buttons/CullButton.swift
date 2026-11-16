import SwiftUI

/// Botón principal del sistema de diseño Cull (`ds.md` - Actions).
/// Soporta variantes Primaria, Destructiva, Secundaria, Outline y Ghost con iconos decorativos opcionales.
public struct CullButton: View {
    public let title: String
    public let systemImage: String?
    public let variant: CullButtonVariant
    public let isFullWidth: Bool
    public let isCapsule: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        variant: CullButtonVariant = .primary,
        isFullWidth: Bool = false,
        isCapsule: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.isFullWidth = isFullWidth
        self.isCapsule = isCapsule
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
            }
        }
        .buttonStyle(
            CullButtonStyle(
                variant: variant,
                isFullWidth: isFullWidth,
                height: 48,
                isCapsule: isCapsule
            )
        )
    }
}

// MARK: - Previews
#Preview("Cull Buttons") {
    VStack(spacing: AppTheme.Spacing.medium) {
        // Como en la imagen de referencia:
        CullButton("Analizar fotos", variant: .primary) {}
        CullButton("Depurar seleccionadas", systemImage: "trash.fill", variant: .destructive) {}
        CullButton("Conservar todas", variant: .secondary) {}
        CullButton("Cancelar", variant: .outline) {}
    }
    .padding()
}
