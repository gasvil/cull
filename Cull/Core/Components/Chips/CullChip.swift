import SwiftUI

/// Variantes semánticas para los chips de feedback y filtros según `ds.md`.
public enum CullChipVariant: Sendable {
    case neutral(dotColor: Color? = nil)
    case cull
    case keep
    case pending

    public var containerColor: Color {
        switch self {
        case .neutral:
            return AppColor.surfaceContainerLow
        case .cull:
            return AppColor.cullContainer
        case .keep:
            return AppColor.keepContainer
        case .pending:
            return AppColor.pendingContainer
        }
    }

    public var foregroundColor: Color {
        switch self {
        case .neutral:
            return AppColor.onSurface
        case .cull:
            return AppColor.onCullContainer
        case .keep:
            return AppColor.onKeepContainer
        case .pending:
            return AppColor.onPendingContainer
        }
    }

    public var defaultIcon: String? {
        switch self {
        case .neutral:
            return nil
        case .cull:
            return "trash.fill"
        case .keep:
            return "bookmark.fill"
        case .pending:
            return "clock.fill"
        }
    }
}

/// Componente Chip interactivo y accesible del sistema de diseño Cull (`ds.md` - Chips).
/// Reproduce exactamente los chips de filtro y estado mostrados en la especificación visual:
/// "Todas" (con punto azul), "Eliminar (4)" (cull container) y "Guardar (Mejor toma)" (keep container).
public struct CullChip: View {
    public let title: String
    public let systemImage: String?
    public let variant: CullChipVariant
    public let isSelected: Bool
    public let action: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        _ title: String,
        systemImage: String? = nil,
        variant: CullChipVariant = .neutral(),
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage ?? variant.defaultIcon
        self.variant = variant
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                chipContent
            }
            .buttonStyle(CullChipPressStyle(reduceMotion: reduceMotion))
        } else {
            chipContent
        }
    }

    private var chipContent: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            // Indicador de punto circular si está presente en la variante neutra
            if case .neutral(let dotColor) = variant, let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(variant.foregroundColor)
            }

            Text(title)
                .font(AppFont.labelMedium)
                .foregroundColor(variant.foregroundColor)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(variant.containerColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isSelected ? variant.foregroundColor : AppColor.outlineVariant,
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        // Garantizar área de toque mínima de 44 pt si es interactivo
        .frame(minHeight: action != nil ? 44 : 0)
        .contentShape(Capsule())
    }
}

private struct CullChipPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : AppMotion.stateChange, value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

// MARK: - Previews
#Preview("Cull Chips") {
    HStack(spacing: AppTheme.Spacing.small) {
        // Como en la imagen de referencia:
        CullChip("Todas", variant: .neutral(dotColor: Color.blue), isSelected: true) {}
        CullChip("Eliminar (4)", variant: .cull) {}
        CullChip("Guardar (Mejor toma)", variant: .keep) {}
    }
    .padding()
}
