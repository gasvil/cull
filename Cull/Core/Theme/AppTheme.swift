import SwiftUI

/// Tokens de diseño y constantes de interfaz de usuario para Cull.
/// Centraliza espaciados, bordes y estilos (DRY / High Cohesion).
public enum AppTheme {
    public enum Spacing {
        public static let xxSmall: CGFloat = 4
        public static let xSmall: CGFloat = 8
        public static let small: CGFloat = 12
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let xLarge: CGFloat = 32
    }

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
    }
}
