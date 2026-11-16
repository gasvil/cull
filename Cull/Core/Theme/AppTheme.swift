import SwiftUI

/// Tokens de diseño y constantes de interfaz de usuario para Cull.
/// Centraliza espaciados, bordes y estilos (DRY / High Cohesion).
public enum AppTheme {
    public enum Spacing {
        public static let xxSmall: CGFloat = 4      // gutter-xs
        public static let xSmall: CGFloat = 8       // gutter-sm
        public static let small: CGFloat = 12       // gutter-md
        public static let medium: CGFloat = 16      // gutter-lg & page-margin
        public static let large: CGFloat = 24       // gutter-xl
        public static let xLarge: CGFloat = 32      // section
    }

    public enum CornerRadius {
        public static let sm: CGFloat = 6
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12      // default
        public static let large: CGFloat = 16       // md
        public static let xl: CGFloat = 20          // lg
        public static let xxl: CGFloat = 24         // xl
        public static let full: CGFloat = 9999      // full / capsule
    }
}
