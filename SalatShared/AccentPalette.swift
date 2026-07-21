import SwiftUI

/// Resolved, render-ready colors for one Live Activity frame.
///
/// Everything here is computed from the single main keyframe; no view ever
/// hand-picks a second color. Accent derivation follows the house rule:
/// three slots -> triadic (main hue +/- 120), two slots -> complementary
/// (+180), and everything collapses to neutral grays inside the desaturated
/// noon zone where hue math stops meaning anything.
struct SalatResolved {
    /// Primary surface color (background top).
    let surface: Color
    /// Self-derived deeper variant of the surface (background bottom).
    let surfaceDeep: Color
    /// Foreground text/glyph color chosen by luminance flip.
    let ink: Color
    /// Muted foreground for secondary labels.
    let inkMuted: Color
    /// Derived accents, count matches the requested slot count.
    let accents: [Color]
    /// SF Symbol for the current period.
    let symbol: String
    /// Tracked-caps period label for the current period.
    let label: String
}

enum AccentPalette {

    /// Resolve the full render package for a phase.
    ///
    /// - Parameters:
    ///   - phaseId: palette anchor id from `ContentState`.
    ///   - progress: 0...1 position toward the next anchor.
    ///   - dark: true when rendering for a dark appearance (the Dynamic
    ///     Island always passes true; lock screen follows the environment).
    ///   - slots: number of accent colors needed (2 = complementary,
    ///     3 = triadic, anything else clamps into that range).
    static func resolve(phaseId: String, progress: Double, dark: Bool, slots: Int) -> SalatResolved {
        let (hsl, anchor) = SalatPalette.state(phaseId: phaseId, progress: progress)

        let surface = SalatPalette.color(hsl, dark: dark)
        // The gradient's second stop is always the same hue, 12% deeper.
        let surfaceDeep = SalatPalette.color(hsl, dark: dark, lightnessOffset: -0.12)

        // Luminance flip: light surfaces get a warm near-black ink, dark
        // surfaces get warm off-white, mirroring the app's editorial palette.
        let isLightSurface = SalatPalette.luminance(hsl, dark: dark) >= 0.5
        let ink: Color = isLightSurface
            ? Color(red: 0.10, green: 0.09, blue: 0.08)
            : Color(red: 0.93, green: 0.89, blue: 0.82)
        let inkMuted = ink.opacity(0.72)

        let clampedSlots = min(max(slots, 2), 3)
        let accents = deriveAccents(from: hsl, dark: dark, slots: clampedSlots, lightSurface: isLightSurface)

        return SalatResolved(
            surface: surface,
            surfaceDeep: surfaceDeep,
            ink: ink,
            inkMuted: inkMuted,
            accents: accents,
            symbol: anchor.symbol,
            label: anchor.label
        )
    }

    /// Derive accent colors from the main keyframe.
    private static func deriveAccents(from hsl: SalatHSL, dark: Bool, slots: Int, lightSurface: Bool) -> [Color] {
        // Inside the noon desaturation zone, hue rotation produces garbage;
        // collapse every accent to a neutral gray at a contrasting lightness.
        guard hsl.sat >= SalatPalette.saturationGuard else {
            let l = lightSurface ? 0.35 : 0.80
            return (0..<slots).map { i in
                // Stagger grays slightly so stacked accents stay separable.
                let g = min(max(l + Double(i) * (lightSurface ? -0.08 : 0.06), 0), 1)
                return Color(red: g, green: g, blue: g)
            }
        }

        // Hue offsets by slot count: complementary for 2, triadic for 3.
        let offsets: [Double] = slots == 2 ? [180, 180] : [120, -120, 180]

        // Accents sit at moderated saturation and a lightness pushed away
        // from the surface so they read as marks, not fill.
        let accentL = lightSurface
            ? max(hsl.lightness(dark: dark) - 0.28, 0.18)
            : min(hsl.lightness(dark: dark) + 0.32, 0.85)

        return (0..<slots).map { i in
            var h = (hsl.hue + offsets[i]).truncatingRemainder(dividingBy: 360)
            if h < 0 { h += 360 }
            // Second complementary slot is the same hue, quieter, so the two
            // lock screen accents remain related rather than clashing.
            let s = (slots == 2 && i == 1) ? 0.30 : min(max(hsl.sat, 0.55), 0.70)
            let c = SalatPalette.rgb(hue: h, sat: s, lightness: accentL)
            return Color(red: c.r, green: c.g, blue: c.b)
        }
    }
}
