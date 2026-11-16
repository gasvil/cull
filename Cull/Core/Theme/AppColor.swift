import SwiftUI
import UIKit

/// Tokens de color semánticos definidos en `ds.md`.
/// Soportan modo claro y oscuro de manera adaptativa.
public enum AppColor {
    // MARK: - Core Accents & Roles
    public static let accent = dynamicColor(light: "#2563EB", dark: "#3B82F6")
    public static let cull = dynamicColor(light: "#E11D48", dark: "#F43F5E")
    public static let onCull = Color.white
    public static let cullContainer = dynamicColor(light: "#FFE4E6", dark: "#3F111E")
    public static let onCullContainer = dynamicColor(light: "#9F1239", dark: "#FDA4AF")

    public static let keep = dynamicColor(light: "#059669", dark: "#10B981")
    public static let onKeep = Color.white
    public static let keepContainer = dynamicColor(light: "#D1FAE5", dark: "#064E3B")
    public static let onKeepContainer = dynamicColor(light: "#065F46", dark: "#6EE7B7")

    public static let pending = dynamicColor(light: "#D97706", dark: "#F59E0B")
    public static let onPending = Color.white
    public static let pendingContainer = dynamicColor(light: "#FEF3C7", dark: "#451A03")
    public static let onPendingContainer = dynamicColor(light: "#92400E", dark: "#FCD34D")

    // MARK: - Surfaces & Canvas
    public static let primary = dynamicColor(light: "#0F172A", dark: "#F8FAFC")
    public static let onPrimary = dynamicColor(light: "#FFFFFF", dark: "#0F172A")
    public static let primaryContainer = dynamicColor(light: "#F1F5F9", dark: "#1E293B")
    public static let onPrimaryContainer = dynamicColor(light: "#0F172A", dark: "#F8FAFC")

    public static let surface = dynamicColor(light: "#FFFFFF", dark: "#090D14")
    public static let surfaceContainerLow = dynamicColor(light: "#F8FAFC", dark: "#0F172A")
    public static let surfaceContainer = dynamicColor(light: "#F1F5F9", dark: "#1E293B")
    public static let surfaceContainerHigh = dynamicColor(light: "#E2E8F0", dark: "#334155")

    public static let onSurface = dynamicColor(light: "#0F172A", dark: "#F8FAFC")
    public static let onSurfaceVariant = dynamicColor(light: "#64748B", dark: "#94A3B8")

    public static let outline = dynamicColor(light: "#CBD5E1", dark: "#475569")
    public static let outlineVariant = dynamicColor(light: "#E2E8F0", dark: "#334155")

    // MARK: - Helper Dinámico
    private static func dynamicColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: dark) ?? .white
            } else {
                return UIColor(hex: light) ?? .black
            }
        })
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }

        guard cleanHex.count == 6, let intVal = UInt64(cleanHex, radix: 16) else {
            return nil
        }

        let r = CGFloat((intVal & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((intVal & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(intVal & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
