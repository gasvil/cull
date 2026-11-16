---
name: "Cull Minimalist Studio"
description: "A refined, hyper-minimalist iOS design system for intelligent photo curation and decluttering."
---

## Overview

Cull is an intelligent iOS photo curation companion. Its mission is to transform overwhelming photo libraries into curated, intentional memories with clarity and zero friction.

The design embodies **Warm Tech Minimalism**: airy whitespace, pristine neutral canvas surfaces, crisp micro-borders, and high-legibility neo-grotesque typography. It takes inspiration from contemporary Swiss editorial apps and premium camera interfaces—calm, confident, and delightfully functional. Every visual decision directs focus to the photography itself while clearly communicating curation intent (keepers vs. purges).

All UI is built with SwiftUI on iOS 17+ and follows `agents.md` (Swift 6, Observation, strict concurrency). Implement these tokens in `Core/Theme`; never hardcode colors, spacing, or fonts inside views.

## Colors

The palette revolves around deep charcoal slate neutrals with a focused electric sapphire primary and deliberate functional semantic roles: a decisive carmine coral for items preselected for deletion/cleanup, an emerald sage for saved/retained favorites, and an amber gold for photos awaiting user validation.

- **Primary:** Deep sapphire (`#1D242B`) with an adaptive active accent (`#2563EB`) that conveys precision and utility.
- **Destructive/Cull:** Carmine coral (`#E11D48`) applied to preselected burst rejects, utility receipts, and deficient accidental shots.
- **Success/Keep:** Emerald sage (`#059669`) for guaranteed keepers, star shots, and burst heroes.
- **Warning/Pending:** Warm amber (`#D97706`) for items categorized as "Por Validar" requiring conscious confirmation.

### Color tokens

```yaml
colors:
  accent: "#2563EB"
  cull: "#E11D48"
  on-cull: "#FFFFFF"
  cull-container: "#FFE4E6"
  on-cull-container: "#9F1239"
  keep: "#059669"
  on-keep: "#1C1C1C"
  keep-container: "#D1FAE5"
  on-keep-container: "#065F46"
  pending: "#D97706"
  on-pending: "#2A2A2A"
  pending-container: "#FEF3C7"
  on-pending-container: "#92400E"
  light:
    primary: "#0F172A"
    on-primary: "#FFFFFF"
    primary-container: "#F1F5F9"
    on-primary-container: "#0F172A"
    surface: "#FFFFFF"
    surface-container-low: "#F8FAFC"
    surface-container: "#F1F5F9"
    surface-container-high: "#E2E8F0"
    on-surface: "#0F172A"
    on-surface-variant: "#64748B"
    outline: "#CBD5E1"
    outline-variant: "#E2E8F0"
  dark:
    primary: "#F8FAFC"
    on-primary: "#0F172A"
    primary-container: "#1E293B"
    on-primary-container: "#F8FAFC"
    surface: "#090D14"
    surface-container-low: "#0F172A"
    surface-container: "#1E293B"
    surface-container-high: "#334155"
    on-surface: "#F8FAFC"
    on-surface-variant: "#94A3B8"
    outline: "#475569"
    outline-variant: "#334155"
```

### iOS implementation

- Create a color set in `Assets.xcassets` for every token, with **Any Appearance** and **Dark** values taken from the `light`/`dark` blocks.
- Expose semantic SwiftUI colors in `Core/Theme` (for example `Color.cullAccent`, `Color.surfaceContainerLow`). Views must use semantic tokens, never raw hex values.
- The `on-*` tokens are the only approved foreground colors on their matching containers.
- Never rely on color alone: pair cull/keep/pending with a label, an SF Symbol, or a shape.
- Verify contrast for text and icons in both appearances.

```swift
// Core/Theme — asset-backed semantic colors
enum AppColor {
    static let accent = Color("Accent")
    static let cull = Color("Cull")
    static let keep = Color("Keep")
    static let pending = Color("Pending")
    static let surface = Color("Surface")
    static let surfaceContainerLow = Color("SurfaceContainerLow")
    static let outlineVariant = Color("OutlineVariant")
}
```

## Typography

Pair **Red Hat Text** for crisp, geometric headers with **Instrument Sans** for neutral, legible body labels and metadata, supported by **Spline Sans Mono** for timestamps, file sizes, and burst counts.

### Type tokens

All sizes and line heights are in **points (pt)**.

```yaml
typography:
  display-lg:
    postScriptName: "RedHatText-Bold"
    size: 40
    relativeTo: largeTitle
    lineHeight: 48
    tracking: -0.5
  display-lg-mobile:
    postScriptName: "RedHatText-Bold"
    size: 32
    relativeTo: largeTitle
    lineHeight: 38
    tracking: -0.25
  headline-lg:
    postScriptName: "RedHatText-Bold"
    size: 28
    relativeTo: title
    lineHeight: 34
    tracking: -0.2
  headline-lg-mobile:
    postScriptName: "RedHatText-Bold"
    size: 24
    relativeTo: title
    lineHeight: 30
    tracking: -0.15
  headline-sm:
    postScriptName: "RedHatText-SemiBold"
    size: 18
    relativeTo: headline
    lineHeight: 24
    tracking: 0
  body-lg:
    postScriptName: "InstrumentSans-Regular"
    size: 16
    relativeTo: body
    lineHeight: 24
    tracking: 0
  body-md:
    postScriptName: "InstrumentSans-Regular"
    size: 14
    relativeTo: subheadline
    lineHeight: 20
    tracking: 0
  label-lg:
    postScriptName: "InstrumentSans-SemiBold"
    size: 14
    relativeTo: callout
    lineHeight: 20
    tracking: 0.1
  label-md:
    postScriptName: "InstrumentSans-Medium"
    size: 12
    relativeTo: caption
    lineHeight: 16
    tracking: 0.2
  label-sm:
    postScriptName: "InstrumentSans-SemiBold"
    size: 10
    relativeTo: caption2
    lineHeight: 14
    tracking: 0.4
  mono-sm:
    postScriptName: "SplineSansMono-Medium"
    size: 11
    relativeTo: caption2
    lineHeight: 16
    tracking: 0.2
```

### iOS implementation

- Bundle the font files (`.ttf` or `.otf`) in the app target and register them in `Info.plist` under `UIAppFonts`.
- Use the **PostScript name**, not the family name. Verify names with `UIFont.familyNames` and `UIFont.fontNames(forFamilyName:)`.
- Use `Font.custom(_:size:relativeTo:)` so the type scale responds to Dynamic Type.
- Map `tracking` to `.tracking(_:)` and `lineHeight` to `.lineSpacing(_:)`. For exact line height, use a custom text style based on `UIFont` metrics.
- If a custom font is unavailable, fall back to the system font at the same size and weight until the asset is added.
- Use `@ScaledMetric` for icon sizes, control heights, and spacing that must grow with the text size.

```swift
// Core/Theme — Dynamic Type–aware fonts
enum AppFont {
    static let displayLarge = Font.custom("RedHatText-Bold", size: 32, relativeTo: .largeTitle)
    static let headlineLarge = Font.custom("RedHatText-Bold", size: 24, relativeTo: .title)
    static let headlineSmall = Font.custom("RedHatText-SemiBold", size: 18, relativeTo: .headline)
    static let bodyLarge = Font.custom("InstrumentSans-Regular", size: 16, relativeTo: .body)
    static let bodyMedium = Font.custom("InstrumentSans-Regular", size: 14, relativeTo: .subheadline)
    static let labelLarge = Font.custom("InstrumentSans-SemiBold", size: 14, relativeTo: .callout)
    static let labelMedium = Font.custom("InstrumentSans-Medium", size: 12, relativeTo: .caption)
    static let labelSmall = Font.custom("InstrumentSans-SemiBold", size: 10, relativeTo: .caption2)
    static let monoSmall = Font.custom("SplineSansMono-Medium", size: 11, relativeTo: .caption2)
}
```

## Layout & Spacing

Mobile-optimized single-column layout structured on a fluid **4 pt baseline rhythm**. Generous vertical breathing room creates ease of scanning across dense photo grids.

```yaml
spacing:
  gutter-xs: 4
  gutter-sm: 8
  gutter-md: 12
  gutter-lg: 16
  gutter-xl: 24
  section: 32
  page-margin: 16
```

Map the tokens to `AppTheme.Spacing`:

| Token | Value (pt) | `AppTheme.Spacing` |
|-------|------------|--------------------|
| `gutter-xs` | 4 | `.xxSmall` |
| `gutter-sm` | 8 | `.xSmall` |
| `gutter-md` | 12 | `.small` |
| `gutter-lg` / `page-margin` | 16 | `.medium` |
| `gutter-xl` | 24 | `.large` |
| `section` | 32 | `.xLarge` |

### iOS implementation

- Use `VStack(spacing:)`, `HStack(spacing:)`, and `.padding()` with theme tokens; no magic numbers.
- Use `LazyVGrid` with adaptive columns for photo grids; never build unbounded grids with `VStack`.
- Respect safe areas. Use `safeAreaInset(edge: .bottom)` for floating action bars and `ignoresSafeArea` only for full-bleed photography.
- Keep a 16 pt page margin. Controls should be at least 44 × 44 pt.
- Prefer `frame(maxWidth: .infinity)` over fixed widths so the layout adapts to iPad and landscape.

## Elevation & Depth

Flat, crisp architectural surfaces. Rather than heavy blurred drop shadows, Cull conveys layering through:

1. **Tonal background steps** (`surface` for pure backdrops, `surface-container-low` for floating cards).
2. **Subtle 1 pt border outlines** (`outline-variant`) with soft contrast.
3. **Translucent materials** for floating action bars, using `.regularMaterial` or `.ultraThinMaterial`.

### iOS implementation

```swift
RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
    .fill(AppColor.surfaceContainerLow)
    .overlay {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .strokeBorder(AppColor.outlineVariant, lineWidth: 1)
    }
```

- Do not use `shadow()` for cards; use surface steps and outlines.
- Floating bars use `.background(.regularMaterial)` plus a hairline top border.
- Keep overlays within the safe area and ensure content behind materials remains legible.

## Shapes

Organic, ergonomic corners matching iOS device contours.

```yaml
rounded:
  sm: 6
  default: 12
  md: 16
  lg: 20
  xl: 24
  full: 9999
```

- Use `RoundedRectangle(cornerRadius:style: .continuous)` for cards, sheets, and controls.
- Use `Capsule()` for `full` (chips, pills, circular icon buttons).
- Map tokens to `AppTheme.CornerRadius`; extend the enum if a token is missing.
- Avoid clipping photo content with aggressive radii; thumbnails should preserve the image.

## Motion & Micro-interaction

Micro-interactions are snappy and responsive. Batch selections trigger an immediate haptic plus a scale pulse, and category switches glide horizontally.

```yaml
motion:
  state-change:
    duration: 0.12
    curve: [0.4, 0.0, 0.2, 1.0]
  surface-enter:
    duration: 0.22
    curve: [0.16, 1.0, 0.3, 1.0]
  surface-exit:
    duration: 0.15
    curve: [0.3, 0.0, 0.8, 0.15]
```

```swift
enum AppMotion {
    static let stateChange = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.12)
    static let surfaceEnter = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.22)
    static let surfaceExit = Animation.timingCurve(0.3, 0, 0.8, 0.15, duration: 0.15)
}
```

### iOS implementation

- Drive transitions with `withAnimation` or `.animation(_:value:)`; never animate layout on every state change.
- Use `matchedGeometryEffect` or `.transition(.move(edge:))` for category switches.
- Add haptics with `.sensoryFeedback(.impact(weight: .light), trigger: selection)` on iOS 17+.
- Press feedback: scale to `0.98` with `AppMotion.stateChange` and a light impact.
- Respect `@Environment(\.accessibilityReduceMotion)` and skip non-essential motion when enabled.
- Haptics and motion are supplementary; never the only confirmation of an action.

## Voice & Content Strategy

- **Tone:** Concise, helpful, discreet. The copy never scolds or uses emotional guilt about messy libraries.
- **Capitalization:** Sentence case across all titles, badges, and action buttons.
- **Terminology:**
  - "Ráfaga" for burst photo clusters.
  - "Guardar" / "Conservar" for keeper photos.
  - "Liberar" / "Depurar" for confirming deletions.
  - Categories: "Utilitarias", "Deficientes", "Por Validar".
- **Action Labels:** Action-driven verbs naming clear outcomes ("Depurar 18 fotos", "Analizar biblioteca", "Conservar seleccionadas").

### iOS implementation

- Store copy in a String Catalog (`Localizable.xcstrings`); no hardcoded user-facing strings in views.
- Keep sentence case and the Spanish terminology above; use `LocalizedStringKey` for interpolation.
- Ensure labels do not truncate at large Dynamic Type sizes; allow wrapping and avoid fixed widths.
- Provide `accessibilityLabel` for icon-only controls and `accessibilityHint` for destructive actions.

## Components

Implement these as reusable SwiftUI views (in `Core/Theme` or the owning feature).

### Buttons

- **Primary button:** filled `accent` background, `on-accent` label, 12 pt continuous radius, 48 pt minimum height, `label-lg` text.
  - States: default, pressed (0.98 scale + light haptic), disabled (40% opacity, non-interactive).
  - Use a `ButtonStyle` so pressed and disabled states are consistent and accessible.
- **Icon button:** 44 × 44 pt hit area, SF Symbol, tinted with `accent` or `on-surface`. Requires an `accessibilityLabel`.
- **Button with icon:** leading SF Symbol plus label, 8 pt gap; keep the icon decorative and the label explicit.

### Cards

- **Elevated card:** `surface-container-low` fill, 16 pt continuous radius, 1 pt `outline-variant` border, no shadow.
- **Action card:** full-width tappable row, 16 pt padding, trailing chevron, min 44 pt height.
- **Interactive card:** press scale + light haptic; do not use `onTapGesture` for primary actions—use `Button`.

### Chips

- **Action chip:** `Capsule`, 12 pt horizontal padding, `label-md`; selected state uses the matching container color and `on-*` foreground.
- **Input chip:** contains a `TextField` with the same capsule shape; keep the field label visible to VoiceOver.
- **Chip with icon:** leading SF Symbol; the icon inherits the chip's foreground color.

### Floating action bar

- Use `safeAreaInset(edge: .bottom)` with `.regularMaterial` background and a 1 pt top `outline-variant` border.
- 16 pt horizontal page margin; primary action on the trailing edge.
- Collapse or hide secondary actions at large Dynamic Type sizes; never overlap content.

### Photo grid

- Use `LazyVGrid` with adaptive columns and stable aspect ratios.
- Show selection state with a border, checkmark, and accessibility value—not color alone.
- Downsample thumbnails; never decode full-resolution assets in the grid.

## Accessibility

- Support Dynamic Type through the largest accessibility sizes; test with `AX5`.
- Provide VoiceOver labels and hints for every icon-only or image-only control.
- Maintain at least 4.5:1 contrast for body text and 3:1 for large text and UI components.
- Use 44 × 44 pt minimum tap targets.
- Respect Reduce Motion and Reduce Transparency.
- Convey cull/keep/pending with text or symbols in addition to color.
- Announce destructive confirmation with a clear label and a non-destructive default action.

## Asset Checklist

- [ ] Color sets added for every token with Any/Dark appearances.
- [ ] Font files added to the app target and registered in `UIAppFonts`.
- [ ] PostScript names verified at runtime.
- [ ] `AppColor`, `AppFont`, `AppTheme`, and `AppMotion` expose semantic tokens only.
- [ ] SwiftUI previews cover light, dark, and the largest Dynamic Type size.
- [ ] No raw hex values, magic spacing, or hardcoded font sizes in feature views.
