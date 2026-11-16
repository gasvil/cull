import SwiftUI

/// Variantes visuales para `CullButton` según `ds.md`.
public enum CullButtonVariant: Sendable {
    case primary
    case destructive
    case secondary
    case outline
    case ghost
}

/// Estilo de botón reutilizable que aplica las curvas de animación y escala de `ds.md`.
public struct CullButtonStyle: ButtonStyle {
    public let variant: CullButtonVariant
    public let isFullWidth: Bool
    public let height: CGFloat
    public let isCapsule: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        variant: CullButtonVariant = .primary,
        isFullWidth: Bool = false,
        height: CGFloat = 48,
        isCapsule: Bool = true
    ) {
        self.variant = variant
        self.isFullWidth = isFullWidth
        self.height = height
        self.isCapsule = isCapsule
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.labelLarge)
            .padding(.horizontal, AppTheme.Spacing.large)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: max(44, height))
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .modifier(ButtonShapeModifier(isCapsule: isCapsule, isOutline: variant == .outline))
            .opacity(isEnabled ? 1.0 : 0.40)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : AppMotion.stateChange, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return isPressed ? AppColor.primary.opacity(0.85) : AppColor.primary
        case .destructive:
            return isPressed ? AppColor.cull.opacity(0.85) : AppColor.cull
        case .secondary:
            return isPressed ? AppColor.surfaceContainerHigh : AppColor.surfaceContainer
        case .outline:
            return isPressed ? AppColor.surfaceContainerLow : Color.clear
        case .ghost:
            return isPressed ? AppColor.surfaceContainerLow : Color.clear
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return AppColor.onPrimary
        case .destructive:
            return AppColor.onCull
        case .secondary, .outline:
            return AppColor.onSurface
        case .ghost:
            return AppColor.accent
        }
    }
}

// MARK: - ButtonShapeModifier
private struct ButtonShapeModifier: ViewModifier {
    let isCapsule: Bool
    let isOutline: Bool

    func body(content: Content) -> some View {
        if isCapsule {
            content
                .clipShape(Capsule())
                .overlay {
                    if isOutline {
                        Capsule().strokeBorder(AppColor.outlineVariant, lineWidth: 1)
                    }
                }
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
                .overlay {
                    if isOutline {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
                    }
                }
        }
    }
}
