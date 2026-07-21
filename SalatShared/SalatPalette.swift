import SwiftUI

// MARK: - SalatHSL

/// A color keyframe in HSL terms with per-appearance lightness.
///
/// Hue and saturation are shared between Light and Dark Mode; only lightness
/// differs. This is the single place the "what color is the sky right now"
/// question is answered; nothing downstream hand-picks colors.
struct SalatHSL: Equatable {
    /// Hue in degrees, 0..<360.
    var hue: Double
    /// Saturation 0...1.
    var sat: Double
    /// Lightness 0...1 used when rendering in Light Mode.
    var lightModeL: Double
    /// Lightness 0...1 used when rendering in Dark Mode.
    var darkModeL: Double

    /// Lightness for the requested appearance.
    func lightness(dark: Bool) -> Double {
        dark ? darkModeL : lightModeL
    }
}

// MARK: - SalatAnchor

/// One named point on the solar color cycle. Anchors are ordered and cyclical:
/// the segment after the last anchor wraps to the first.
struct SalatAnchor: Identifiable {
    /// Stable identifier used in `ContentState.phaseId` and push payloads.
    let id: String
    /// The color at this anchor.
    let hsl: SalatHSL
    /// SF Symbol communicating the period with color removed.
    let symbol: String
    /// Short tracked-caps period label ("SOLAR NOON", "FIRST WATCH", ...).
    let label: String
}

// MARK: - SalatPalette

/// The solar color cycle: a day arc where hue sweeps warm -> neutral -> warm,
/// and a night arc where hue locks near 0 and only lightness moves. Dusk
/// settles at pure 0 degrees while dawn leans magenta (348-355), which is the
/// primary "which way is time moving" cue.
enum SalatPalette {

    /// Ordered, cyclical anchor list. The cycle begins at fajr (night.nh12),
    /// runs through the day arc (sunrise..maghrib) and the night arc
    /// (maghrib..next fajr), then wraps.
    static let anchors: [SalatAnchor] = [
        // Dawn: night arc terminus, magenta-leaning red.
        SalatAnchor(id: "night.nh12", hsl: SalatHSL(hue: 348, sat: 0.75, lightModeL: 0.44, darkModeL: 0.28), symbol: "sun.haze.fill",         label: "DAWN"),
        // Day arc.
        SalatAnchor(id: "day.rh0",    hsl: SalatHSL(hue: 30,  sat: 0.85, lightModeL: 0.62, darkModeL: 0.38), symbol: "sunrise.fill",          label: "SUNRISE"),
        SalatAnchor(id: "day.rh2",    hsl: SalatHSL(hue: 45,  sat: 0.80, lightModeL: 0.68, darkModeL: 0.42), symbol: "sun.min.fill",          label: "MORNING"),
        SalatAnchor(id: "day.rh4",    hsl: SalatHSL(hue: 52,  sat: 0.60, lightModeL: 0.76, darkModeL: 0.46), symbol: "sun.min.fill",          label: "HIGH MORNING"),
        SalatAnchor(id: "day.rh6",    hsl: SalatHSL(hue: 50,  sat: 0.06, lightModeL: 0.93, darkModeL: 0.52), symbol: "sun.max.fill",          label: "SOLAR NOON"),
        SalatAnchor(id: "day.rh8",    hsl: SalatHSL(hue: 50,  sat: 0.55, lightModeL: 0.78, darkModeL: 0.46), symbol: "sun.min.fill",          label: "AFTERNOON"),
        SalatAnchor(id: "day.rh9",    hsl: SalatHSL(hue: 45,  sat: 0.75, lightModeL: 0.70, darkModeL: 0.43), symbol: "sun.and.horizon.fill",  label: "AFTERNOON"),
        SalatAnchor(id: "day.rh11",   hsl: SalatHSL(hue: 30,  sat: 0.85, lightModeL: 0.60, darkModeL: 0.38), symbol: "sun.and.horizon.fill",  label: "GOLDEN HOUR"),
        SalatAnchor(id: "day.rh12",   hsl: SalatHSL(hue: 12,  sat: 0.90, lightModeL: 0.52, darkModeL: 0.34), symbol: "sunset.fill",           label: "SUNSET"),
        // Night arc: hue locks near pure red, lightness carries the signal.
        SalatAnchor(id: "night.nh0",  hsl: SalatHSL(hue: 12,  sat: 0.85, lightModeL: 0.45, darkModeL: 0.30), symbol: "sunset.fill",           label: "DUSK"),
        SalatAnchor(id: "night.nh1",  hsl: SalatHSL(hue: 0,   sat: 0.85, lightModeL: 0.38, darkModeL: 0.24), symbol: "moon.fill",             label: "FIRST WATCH"),
        SalatAnchor(id: "night.nh4",  hsl: SalatHSL(hue: 0,   sat: 0.80, lightModeL: 0.28, darkModeL: 0.16), symbol: "moon.stars.fill",       label: "MIDDLE WATCH"),
        SalatAnchor(id: "night.nh6",  hsl: SalatHSL(hue: 0,   sat: 0.75, lightModeL: 0.20, darkModeL: 0.10), symbol: "moon.stars.fill",       label: "SOLAR MIDNIGHT"),
        SalatAnchor(id: "night.nh8",  hsl: SalatHSL(hue: 355, sat: 0.75, lightModeL: 0.26, darkModeL: 0.15), symbol: "moon.haze.fill",        label: "LAST WATCH"),
        SalatAnchor(id: "night.nh11", hsl: SalatHSL(hue: 350, sat: 0.80, lightModeL: 0.36, darkModeL: 0.22), symbol: "moon.haze.fill",        label: "APPROACHING DAWN"),
    ]

    /// Saturation below which hue math is considered meaningless (the noon
    /// zone). Accents collapse to neutral grays under this threshold.
    static let saturationGuard: Double = 0.15

    /// Index of an anchor by id, or nil for unknown ids (defensive against
    /// payloads from a newer server than this client).
    static func index(of phaseId: String) -> Int? {
        anchors.firstIndex { $0.id == phaseId }
    }

    /// Interpolate between two keyframes. Hue takes the shortest path around
    /// the wheel; near-zero saturation endpoints hold the other endpoint's hue
    /// instead of spinning through the desaturated zone.
    static func interpolate(from a: SalatHSL, to b: SalatHSL, fraction rawT: Double) -> SalatHSL {
        let t = min(max(rawT, 0), 1)

        // Shortest-path hue wrap: 350 -> 10 crosses 0, not the long way round.
        var delta = (b.hue - a.hue).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        var hue = a.hue + delta * t

        // Saturation guard: when either endpoint is effectively gray, pin hue
        // to the saturated endpoint so no phantom hue sweep is visible.
        if a.sat < saturationGuard { hue = b.hue }
        if b.sat < saturationGuard { hue = a.hue }

        hue = hue.truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }

        return SalatHSL(
            hue: hue,
            sat: a.sat + (b.sat - a.sat) * t,
            lightModeL: a.lightModeL + (b.lightModeL - a.lightModeL) * t,
            darkModeL: a.darkModeL + (b.darkModeL - a.darkModeL) * t
        )
    }

    /// The interpolated color for a phase id + progress pair, plus the anchor
    /// whose glyph/label applies. Unknown ids fall back to solar noon, the
    /// most neutral state.
    static func state(phaseId: String, progress: Double) -> (hsl: SalatHSL, anchor: SalatAnchor) {
        guard let i = index(of: phaseId) else {
            let noon = anchors[4]
            return (noon.hsl, noon)
        }
        let a = anchors[i]
        let b = anchors[(i + 1) % anchors.count]
        return (interpolate(from: a.hsl, to: b.hsl, fraction: progress), a)
    }

    // MARK: Rendering

    /// Convert HSL to sRGB components (standard hexcone model).
    static func rgb(hue: Double, sat: Double, lightness: Double) -> (r: Double, g: Double, b: Double) {
        let h = hue.truncatingRemainder(dividingBy: 360) / 360
        let s = min(max(sat, 0), 1)
        let l = min(max(lightness, 0), 1)

        guard s > 0 else { return (l, l, l) }

        /// Helper resolving one channel from the intermediate q/p values.
        func channel(_ p: Double, _ q: Double, _ rawT: Double) -> Double {
            var t = rawT
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        return (channel(p, q, h + 1 / 3), channel(p, q, h), channel(p, q, h - 1 / 3))
    }

    /// SwiftUI color for a keyframe in the requested appearance.
    static func color(_ hsl: SalatHSL, dark: Bool, lightnessOffset: Double = 0) -> Color {
        let c = rgb(hue: hsl.hue, sat: hsl.sat, lightness: min(max(hsl.lightness(dark: dark) + lightnessOffset, 0), 1))
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    /// WCAG-weighted relative luminance of a keyframe as rendered.
    static func luminance(_ hsl: SalatHSL, dark: Bool) -> Double {
        let c = rgb(hue: hsl.hue, sat: hsl.sat, lightness: hsl.lightness(dark: dark))
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }

    // MARK: Perceptual distance (OKLab)

    /// Approximate perceptual distance between two keyframes in a given
    /// appearance, via OKLab. Used by the scheduler to thin keyframes so
    /// updates cluster where the eye can actually see change.
    static func perceptualDistance(_ a: SalatHSL, _ b: SalatHSL, dark: Bool) -> Double {
        let la = oklab(rgb(hue: a.hue, sat: a.sat, lightness: a.lightness(dark: dark)))
        let lb = oklab(rgb(hue: b.hue, sat: b.sat, lightness: b.lightness(dark: dark)))
        let dL = la.0 - lb.0, dA = la.1 - lb.1, dB = la.2 - lb.2
        return (dL * dL + dA * dA + dB * dB).squareRoot()
    }

    /// sRGB -> OKLab conversion (Björn Ottosson's reference constants).
    private static func oklab(_ c: (r: Double, g: Double, b: Double)) -> (Double, Double, Double) {
        /// Inverse sRGB companding to linear light.
        func lin(_ v: Double) -> Double {
            v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = lin(c.r), g = lin(c.g), b = lin(c.b)

        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

        return (
            0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }
}
