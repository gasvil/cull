import SwiftUI
import UIKit

/// Escala tipográfica sensible a Dynamic Type conforme a `ds.md`.
/// Si las fuentes personalizadas no están cargadas en el bundle, utiliza fallback al sistema con pesos equivalentes.
public enum AppFont {
    public static let displayLarge = font(custom: "RedHatText-Bold", size: 32, weight: .bold, relativeTo: .largeTitle)
    public static let headlineLarge = font(custom: "RedHatText-Bold", size: 24, weight: .bold, relativeTo: .title)
    public static let headlineSmall = font(custom: "RedHatText-SemiBold", size: 18, weight: .semibold, relativeTo: .headline)
    public static let bodyLarge = font(custom: "InstrumentSans-Regular", size: 16, weight: .regular, relativeTo: .body)
    public static let bodyMedium = font(custom: "InstrumentSans-Regular", size: 14, weight: .regular, relativeTo: .subheadline)
    public static let labelLarge = font(custom: "InstrumentSans-SemiBold", size: 14, weight: .semibold, relativeTo: .callout)
    public static let labelMedium = font(custom: "InstrumentSans-Medium", size: 12, weight: .medium, relativeTo: .caption)
    public static let labelSmall = font(custom: "InstrumentSans-SemiBold", size: 10, weight: .semibold, relativeTo: .caption2)
    public static let monoSmall = font(custom: "SplineSansMono-Medium", size: 11, weight: .medium, relativeTo: .caption2, isMonospaced: true)

    private static func font(
        custom: String,
        size: CGFloat,
        weight: Font.Weight,
        relativeTo textStyle: Font.TextStyle,
        isMonospaced: Bool = false
    ) -> Font {
        if UIFont(name: custom, size: size) != nil {
            return Font.custom(custom, size: size, relativeTo: textStyle)
        } else {
            let base = Font.system(size: size, weight: weight, design: isMonospaced ? .monospaced : .default)
            return base
        }
    }
}
