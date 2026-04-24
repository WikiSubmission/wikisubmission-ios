import SwiftUI
import UIKit

// MARK: - DS — Editorial ("Ink on Parchment" / "Night Scholar") design tokens
//
// Mirrors the tokens defined in the web app (wikisubmission-org/app/globals.css).
// Anything user-facing should pull from here instead of using system tints,
// .serif font designs, or raw RoundedRectangles. See EdCard, EdButton,
// SectionDivider, StatBlock below for the canonical component surface.

enum DS {

    // MARK: Spacing & Radius

    enum Spacing {
        static let xxs:     CGFloat = 2
        static let xs:      CGFloat = 4
        static let sm:      CGFloat = 8
        static let md:      CGFloat = 12
        static let lg:      CGFloat = 16
        static let xl:      CGFloat = 24
        static let xxl:     CGFloat = 32
        static let section: CGFloat = 48
    }

    /// Editorial design favours hairline rules and tight radii. Pill is retained
    /// only for capsule controls (e.g. toggles). No heavy rounded cards.
    enum Radius {
        static let hair: CGFloat = 2
        static let sm:   CGFloat = 3
        static let md:   CGFloat = 6
        static let lg:   CGFloat = 10
        static let pill: CGFloat = 999
    }

    enum Hairline {
        static let width: CGFloat = 1
    }

    // MARK: Colors (editorial palette)
    //
    // Two parallel palettes:
    //   Light: Ink on Parchment
    //   Dark:  Night Scholar
    //
    // Exposed via dynamic Color values that resolve at render time. Keep the
    // semantic names (bg, surface, fg, rule, accent…) stable — the hex values
    // may shift but the roles should not.

    enum Color {
        // Parchment / ink (base)
        static let bg         = dynamic(light: 0xF6F2EA, dark: 0x14110E)
        static let bgAlt      = dynamic(light: 0xEFE8D9, dark: 0x0F0D0B)
        static let surface    = dynamic(light: 0xFBF8F1, dark: 0x1C1815)
        static let surfaceHi  = dynamic(light: 0xD9CFB9, dark: 0x2A241E)
        static let fg         = dynamic(light: 0x1A1715, dark: 0xEEE4D0)
        static let fgMuted    = dynamic(light: 0x6A6158, dark: 0x8A8075)
        static let rule       = dynamic(light: 0xD9CFB9, dark: 0x2A241E)
        static let ruleStrong = dynamic(light: 0x6A6158, dark: 0x8A8075)

        // Accent (cocoa in light, warm sand in dark)
        static let accent      = dynamic(light: 0x6B3410, dark: 0xD4A373)
        static let accentSoft  = dynamic(light: 0xECD9C5, dark: 0x3A2A1C)
        static let accentDeep  = dynamic(light: 0x8B4A1C, dark: 0x8B4A1C)

        // Semantic
        static let destructive = dynamic(light: 0xB03A2E, dark: 0xE07060)

        // UIKit twins — for UITabBarAppearance etc.
        static let uiBg      = uiDynamic(light: 0xF6F2EA, dark: 0x14110E)
        static let uiSurface = uiDynamic(light: 0xFBF8F1, dark: 0x1C1815)
        static let uiFg      = uiDynamic(light: 0x1A1715, dark: 0xEEE4D0)
        static let uiFgMuted = uiDynamic(light: 0x6A6158, dark: 0x8A8075)
        static let uiRule    = uiDynamic(light: 0xD9CFB9, dark: 0x2A241E)
        static let uiAccent  = uiDynamic(light: 0x6B3410, dark: 0xD4A373)
    }

    // MARK: Fonts
    //
    // Display: Cormorant Garamond (editorial headlines; italic for emphasis)
    // Body:    Source Serif 4      (long-form prose)
    // Mono:    JetBrains Mono      (tracked-out caps captions, numeric tags)
    // Arabic:  AmiriQuran          (existing)
    //
    // All pass through Font.custom(_, size:, relativeTo:) so Dynamic Type works.

    enum Font {
        // Raw PostScript names — if any of these stop resolving, print
        // UIFont.familyNames / fontNames(forFamilyName:) to sanity-check.
        private static let displayRegular     = "CormorantGaramond-Regular"
        private static let displayMedium      = "CormorantGaramond-Medium"
        private static let displaySemibold    = "CormorantGaramond-SemiBold"
        private static let displayItalic      = "CormorantGaramond-Italic"
        private static let displayMediumItalic = "CormorantGaramond-MediumItalic"
        private static let displaySemiItalic  = "CormorantGaramond-SemiBoldItalic"

        private static let bodyRegular      = "SourceSerif4-Regular"
        private static let bodyItalic       = "SourceSerif4-Italic"
        private static let bodyMedium       = "SourceSerif4-Medium"
        private static let bodyMediumItalic = "SourceSerif4-MediumItalic"
        private static let bodySemibold     = "SourceSerif4-SemiBold"

        private static let monoRegular  = "JetBrainsMono-Regular"
        private static let monoMedium   = "JetBrainsMono-Medium"
        private static let monoSemibold = "JetBrainsMono-SemiBold"

        private static let arabic = "AmiriQuran-Regular"

        // MARK: Display (headline-scale, Cormorant)
        static func display(_ size: CGFloat, weight: DisplayWeight = .regular, italic: Bool = false, relativeTo: SwiftUI.Font.TextStyle = .largeTitle) -> SwiftUI.Font {
            let name: String
            switch (weight, italic) {
            case (.regular, false):  name = displayRegular
            case (.regular, true):   name = displayItalic
            case (.medium, false):   name = displayMedium
            case (.medium, true):    name = displayMediumItalic
            case (.semibold, false): name = displaySemibold
            case (.semibold, true):  name = displaySemiItalic
            }
            return .custom(name, size: size, relativeTo: relativeTo)
        }

        enum DisplayWeight { case regular, medium, semibold }

        // MARK: Body (Source Serif)
        static func body(_ size: CGFloat, weight: BodyWeight = .regular, italic: Bool = false, relativeTo: SwiftUI.Font.TextStyle = .body) -> SwiftUI.Font {
            let name: String
            switch (weight, italic) {
            case (.regular, false):  name = bodyRegular
            case (.regular, true):   name = bodyItalic
            case (.medium, false):   name = bodyMedium
            case (.medium, true):    name = bodyMediumItalic
            case (.semibold, _):     name = bodySemibold
            }
            return .custom(name, size: size, relativeTo: relativeTo)
        }

        enum BodyWeight { case regular, medium, semibold }

        // MARK: Mono (JetBrains — captions, stats, metadata)
        static func mono(_ size: CGFloat, weight: MonoWeight = .regular, relativeTo: SwiftUI.Font.TextStyle = .caption) -> SwiftUI.Font {
            let name: String
            switch weight {
            case .regular:  name = monoRegular
            case .medium:   name = monoMedium
            case .semibold: name = monoSemibold
            }
            return .custom(name, size: size, relativeTo: relativeTo)
        }

        enum MonoWeight { case regular, medium, semibold }

        // MARK: Arabic
        static func arabic(_ size: CGFloat, relativeTo: SwiftUI.Font.TextStyle = .title2) -> SwiftUI.Font {
            .custom(arabic, size: size, relativeTo: relativeTo)
        }
    }

    // MARK: Semantic Typography presets
    //
    // Canonical text styles. Prefer these over ad-hoc .font(...) calls.

    enum Typography {
        // Display — hero headlines. Very tight line height, deep negative tracking.
        static let heroXL = DS.Font.display(64, weight: .regular, relativeTo: .largeTitle)
        static let heroLG = DS.Font.display(48, weight: .regular, relativeTo: .largeTitle)
        static let heroMD = DS.Font.display(36, weight: .regular, relativeTo: .largeTitle)

        // Section & card titles
        static let titleLG = DS.Font.display(28, weight: .medium, relativeTo: .title)
        static let titleMD = DS.Font.display(22, weight: .medium, relativeTo: .title2)
        static let titleSM = DS.Font.display(18, weight: .medium, relativeTo: .title3)

        // Body prose
        static let bodyLG  = DS.Font.body(17, relativeTo: .body)
        static let body    = DS.Font.body(15, relativeTo: .body)
        static let bodySM  = DS.Font.body(14, relativeTo: .callout)

        // Emphasis
        static let lede    = DS.Font.body(17, weight: .regular, italic: false, relativeTo: .body)
        static let quote   = DS.Font.display(20, weight: .regular, italic: true, relativeTo: .title3)

        // Labels / captions
        static let label     = DS.Font.body(13, weight: .medium, relativeTo: .footnote)
        static let caption   = DS.Font.body(12, relativeTo: .caption)

        // Mono — tracked-out caps
        static let eyebrow   = DS.Font.mono(11, weight: .medium, relativeTo: .caption)
        static let eyebrowSM = DS.Font.mono(10, weight: .medium, relativeTo: .caption2)
        static let eyebrowLG = DS.Font.mono(17, weight: .medium, relativeTo: .caption2)
        static let stat      = DS.Font.mono(11, weight: .medium, relativeTo: .caption)

        // Button text (small uppercase)
        static let button    = DS.Font.body(14, weight: .medium, relativeTo: .subheadline)
    }

    // MARK: Motion
    enum Motion {
        static let fast     = SwiftUI.Animation.easeOut(duration: 0.18)
        static let standard = SwiftUI.Animation.easeOut(duration: 0.28)
        static let slow     = SwiftUI.Animation.easeInOut(duration: 0.42)
    }

    // MARK: - helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> SwiftUI.Color {
        SwiftUI.Color(uiColor: uiDynamic(light: light, dark: dark))
    }

    private static func uiDynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    fileprivate convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >>  8) & 0xFF) / 255.0
        let b = CGFloat( hex        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - SectionLabel (small tracked caps eyebrow)

struct SectionLabel: View {
    let text: String
    var color: Color = DS.Color.fgMuted

    init(_ text: String, color: Color = DS.Color.fgMuted) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(DS.Typography.eyebrow)
            .tracking(2)
            .foregroundStyle(color)
    }
}

// MARK: - SectionDivider — numbered editorial section header

struct SectionDivider: View {
    let number: String
    let title: String
    let caption: String

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            Text(number)
                .font(DS.Font.display(14, weight: .regular, italic: true, relativeTo: .caption))
                .tracking(1.5)
                .foregroundStyle(DS.Color.accent)

            Text(title)
                .font(DS.Typography.titleLG)
                .foregroundStyle(DS.Color.fg)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(DS.Color.rule)
                .frame(height: DS.Hairline.width)
                .frame(maxWidth: .infinity)

            Text(caption.uppercased())
                .font(DS.Typography.eyebrow)
                .tracking(2)
                .foregroundStyle(DS.Color.fgMuted)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - EdCard — hairline-bordered editorial card

struct EdCard<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    var padding: CGFloat = DS.Spacing.lg
    var tint: Color? = nil
    var radius: CGFloat = DS.Radius.sm
    let content: () -> Content

    init(padding: CGFloat = DS.Spacing.lg, tint: Color? = nil, radius: CGFloat = DS.Radius.sm, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.tint = tint
        self.radius = radius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(tint ?? DS.Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Editorial Buttons

enum EdButtonVariant { case primary, ghost, inverted }

struct EdButtonStyle: ButtonStyle {
    var variant: EdButtonVariant = .primary
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.button)
            .padding(.horizontal, compact ? DS.Spacing.md : DS.Spacing.xl)
            .padding(.vertical, compact ? DS.Spacing.sm : DS.Spacing.md)
            .foregroundStyle(fg)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.hair, style: .continuous)
                    .stroke(border, lineWidth: DS.Hairline.width)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.hair, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DS.Motion.fast, value: configuration.isPressed)
    }

    private var fg: Color {
        switch variant {
        case .primary:  return DS.Color.bg
        case .ghost:    return DS.Color.fg
        case .inverted: return DS.Color.fg
        }
    }
    private var bg: Color {
        switch variant {
        case .primary:  return DS.Color.fg
        case .ghost:    return .clear
        case .inverted: return DS.Color.surface
        }
    }
    private var border: Color {
        switch variant {
        case .primary:  return DS.Color.fg
        case .ghost:    return DS.Color.rule
        case .inverted: return DS.Color.rule
        }
    }
}

extension ButtonStyle where Self == EdButtonStyle {
    static func edPrimary(compact: Bool = false) -> EdButtonStyle { .init(variant: .primary, compact: compact) }
    static func edGhost(compact: Bool = false)   -> EdButtonStyle { .init(variant: .ghost, compact: compact) }
    static func edInverted(compact: Bool = false) -> EdButtonStyle { .init(variant: .inverted, compact: compact) }
}

// MARK: - StatBlock — numeric / label pair used in hero & cards

struct StatBlock: View {
    let value: String
    let label: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Spacing.xs) {
            Text(value)
                .font(DS.Font.display(28, weight: .medium, relativeTo: .title))
                .foregroundStyle(DS.Color.fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(DS.Typography.eyebrowSM)
                .tracking(2.2)
                .foregroundStyle(DS.Color.fgMuted)
        }
    }
}

// MARK: - Hairline rule

struct EdRule: View {
    var color: Color = DS.Color.rule
    var body: some View {
        Rectangle().fill(color).frame(height: DS.Hairline.width)
    }
}

// MARK: - ViewModifiers

extension View {
    /// Editorial ScrollView background — applies the parchment bg.
    func edBackground(_ color: Color = DS.Color.bg) -> some View {
        self
            .background(color.ignoresSafeArea())
    }

    /// Paints the navigation bar & scroll background to match editorial bg.
    func edNavAppearance() -> some View {
        self
            .toolbarBackground(DS.Color.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
