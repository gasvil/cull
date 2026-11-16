import SwiftUI

/// Botón de icono accesible con área táctil mínima de 44x44 pt (`ds.md` - Actions).
public struct CullIconButton: View {
    public let systemImage: String
    public let accessibilityLabel: String
    public let tint: Color
    public let backgroundColor: Color
    public let size: CGFloat
    public let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        systemImage: String,
        accessibilityLabel: String,
        tint: Color = AppColor.onSurface,
        backgroundColor: Color = AppColor.surfaceContainer,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.tint = tint
        self.backgroundColor = backgroundColor
        self.size = max(44, size)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
                )
        }
        .buttonStyle(CullIconPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct CullIconPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : AppMotion.stateChange, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

#Preview("Icon Buttons") {
    HStack(spacing: AppTheme.Spacing.medium) {
        CullIconButton(systemImage: "xmark", accessibilityLabel: "Cerrar") {}
        CullIconButton(systemImage: "trash.fill", accessibilityLabel: "Eliminar", tint: AppColor.cull) {}
        CullIconButton(systemImage: "sparkles", accessibilityLabel: "Optimizar", tint: AppColor.accent) {}
    }
    .padding()
}
