import XCTest
import SwiftUI
@testable import Cull

final class DesignSystemColorsAndComponentsTests: XCTestCase {

    func testAppThemeSpacing_matchesDesignSystemSpec() {
        XCTAssertEqual(AppTheme.Spacing.xxSmall, 4)
        XCTAssertEqual(AppTheme.Spacing.xSmall, 8)
        XCTAssertEqual(AppTheme.Spacing.small, 12)
        XCTAssertEqual(AppTheme.Spacing.medium, 16)
        XCTAssertEqual(AppTheme.Spacing.large, 24)
        XCTAssertEqual(AppTheme.Spacing.xLarge, 32)
    }

    func testAppThemeCornerRadius_matchesDesignSystemSpec() {
        XCTAssertEqual(AppTheme.CornerRadius.sm, 6)
        XCTAssertEqual(AppTheme.CornerRadius.small, 8)
        XCTAssertEqual(AppTheme.CornerRadius.medium, 12)
        XCTAssertEqual(AppTheme.CornerRadius.large, 16)
        XCTAssertEqual(AppTheme.CornerRadius.xl, 20)
        XCTAssertEqual(AppTheme.CornerRadius.xxl, 24)
        XCTAssertEqual(AppTheme.CornerRadius.full, 9999)
    }

    func testUIColorHex_validHex_initializesCorrectColor() {
        let redColor = UIColor(hex: "#E11D48")
        XCTAssertNotNil(redColor)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        redColor?.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0xE1 / 255.0, accuracy: 0.01)
        XCTAssertEqual(g, 0x1D / 255.0, accuracy: 0.01)
        XCTAssertEqual(b, 0x48 / 255.0, accuracy: 0.01)

        // Invalid hex
        XCTAssertNil(UIColor(hex: "invalid"))
        XCTAssertNil(UIColor(hex: "#12"))
    }

    func testCategoryPriority_colorsAndText() {
        let high = CategoryPriority.high
        XCTAssertEqual(high.rawValue, "Alta Prioridad")

        let medium = CategoryPriority.medium
        XCTAssertEqual(medium.rawValue, "Prioridad Media")

        let low = CategoryPriority.low
        XCTAssertEqual(low.rawValue, "Baja Prioridad")
    }

    func testCullChipVariant_iconsAndColors() {
        let neutral = CullChipVariant.neutral(dotColor: .blue)
        XCTAssertNil(neutral.defaultIcon)

        let cull = CullChipVariant.cull
        XCTAssertEqual(cull.defaultIcon, "trash.fill")

        let keep = CullChipVariant.keep
        XCTAssertEqual(keep.defaultIcon, "bookmark.fill")

        let pending = CullChipVariant.pending
        XCTAssertEqual(pending.defaultIcon, "clock.fill")
    }
}
