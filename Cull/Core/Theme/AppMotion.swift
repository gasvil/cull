import SwiftUI

/// Tokens de animación y curvas de aceleración conforme a `ds.md`.
public enum AppMotion {
    /// Micro-interacción rápida para cambios de estado y presión de botones (120ms).
    public static let stateChange = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.12)

    /// Entrada de superficies y tarjetas (220ms).
    public static let surfaceEnter = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.22)

    /// Salida de superficies y descartes (150ms).
    public static let surfaceExit = Animation.timingCurve(0.3, 0, 0.8, 0.15, duration: 0.15)
}
