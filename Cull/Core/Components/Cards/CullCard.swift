import SwiftUI

/// Tarjeta base del sistema de diseño Cull (`ds.md` - Containment).
/// Superficie tonal `surfaceContainerLow`, radio continuo de 16 pt y micro-borde de 1 pt sin sombras difusas.
public struct CullCard<Content: View>: View {
    public let isInteractive: Bool
    public let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        isInteractive: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isInteractive = isInteractive
        self.content = content
    }

    public var body: some View {
        Group {
            content()
                .padding(AppTheme.Spacing.medium)
                .background(AppColor.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
                )
        }
    }
}
