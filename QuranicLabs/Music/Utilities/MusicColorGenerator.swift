 import SwiftUI
import UIKit

/// Generates deterministic color themes based on a UUID seed.
/// Used for track artwork backgrounds to provide visual variety.
struct MusicColorTheme {
    /// Gradient for larger card backgrounds
    let cardGradient: LinearGradient
    /// Gradient for artwork thumbnails
    let artworkGradient: LinearGradient
    /// Accent color for highlights
    let accent: Color

    /// Generate a color theme from a UUID seed
    static func generate(seed: UUID?) -> MusicColorTheme {
        var seedVal: UInt64 = 0
        let baseHue: Double

        if let seed = seed {
            let hex = seed.uuidString.replacingOccurrences(of: "-", with: "")
            let prefix = String(hex.prefix(16))
            seedVal = UInt64(prefix, radix: 16) ?? 0
            baseHue = Double(seedVal % 360) / 360.0
        } else {
            baseHue = 0.58
            seedVal = 0xDEADBEEF
        }

        // MARK: - Helper Functions

        /// Deterministic hue offset from seed bits
        func hueOffset(_ idx: Int, spreadDegrees: Double) -> CGFloat {
            let shift = UInt64(idx * 8)
            let chunk = UInt32((seedVal >> shift) & 0xFF)
            let deg = (Double(chunk) / 255.0 - 0.5) * spreadDegrees
            let hue = fmod(baseHue + deg / 360.0 + 1.0, 1.0)
            return CGFloat(hue)
        }

        /// Saturation variation from seed bits
        func saturation(_ idx: Int, base: CGFloat, variance: CGFloat) -> CGFloat {
            let chunk = UInt32((seedVal >> UInt64(idx * 7)) & 0x7F)
            let frac = CGFloat(chunk) / 127.0
            return min(max(base + (frac - 0.5) * variance, 0.12), 0.98)
        }

        /// Brightness for light/dark modes from seed bits
        func brightness(_ idx: Int, lightBase: CGFloat, darkBase: CGFloat, variance: CGFloat) -> (light: CGFloat, dark: CGFloat) {
            let chunk = UInt32((seedVal >> UInt64(idx * 9 + 3)) & 0x7F)
            let frac = CGFloat(chunk) / 127.0
            let light = min(max(lightBase + (frac - 0.5) * variance, 0.05), 0.99)
            let dark = min(max(darkBase + (frac - 0.5) * variance, 0.05), 0.99)
            return (light, dark)
        }

        /// Create adaptive color for light/dark modes
        func adaptiveColor(h: CGFloat, s: CGFloat, lightBrightness: CGFloat, darkBrightness: CGFloat) -> Color {
            Color(UIColor { trait in
                let brightness = (trait.userInterfaceStyle == .dark) ? darkBrightness : lightBrightness
                return UIColor(hue: h, saturation: s, brightness: brightness, alpha: 1)
            })
        }

        // MARK: - Card Gradient (subtle, desaturated)

        let hCard1 = hueOffset(0, spreadDegrees: 30)
        let hCard2 = hueOffset(1, spreadDegrees: 50)
        let hCard3 = hueOffset(2, spreadDegrees: 80)
        let sCard1 = saturation(0, base: 0.22, variance: 0.20)
        let sCard2 = saturation(1, base: 0.30, variance: 0.28)
        let (cardLight, cardDark) = brightness(0, lightBase: 0.97, darkBase: 0.12, variance: 0.12)

        let cardC1 = adaptiveColor(h: hCard1, s: sCard1, lightBrightness: cardLight, darkBrightness: cardDark)
        let cardC2 = adaptiveColor(h: hCard2, s: sCard2, lightBrightness: cardLight * 0.96, darkBrightness: cardDark * 1.06)
        let cardC3 = adaptiveColor(h: hCard3, s: max(sCard1, sCard2) * 0.85, lightBrightness: cardLight * 0.92, darkBrightness: cardDark * 1.12)

        let cardGradient = LinearGradient(
            gradient: Gradient(colors: [cardC1, cardC2, cardC3]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // MARK: - Artwork Gradient (richer, more saturated)

        let hArt1 = hueOffset(3, spreadDegrees: 90)
        let hArt2 = hueOffset(4, spreadDegrees: 140)
        let sArt1 = saturation(2, base: 0.62, variance: 0.30)
        let sArt2 = saturation(3, base: 0.72, variance: 0.22)
        let (artLight, artDark) = brightness(1, lightBase: 0.92, darkBase: 0.22, variance: 0.18)

        let artC1 = adaptiveColor(h: hArt1, s: sArt1, lightBrightness: artLight, darkBrightness: artDark)
        let artC2 = adaptiveColor(h: hArt2, s: sArt2, lightBrightness: artLight * 0.96, darkBrightness: artDark * 1.08)

        let artworkGradient = LinearGradient(
            gradient: Gradient(colors: [artC1, artC2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // MARK: - Accent Color (vivid, complementary)

        let accentHue = CGFloat(fmod((Double(hueOffset(5, spreadDegrees: 120)) + 0.5), 1.0))
        let accentSat = saturation(4, base: 0.86, variance: 0.18)
        let (accentLight, accentDark) = brightness(2, lightBase: 0.72, darkBase: 0.88, variance: 0.10)

        let accentColor = Color(UIColor { trait in
            let b = (trait.userInterfaceStyle == .dark) ? accentDark : accentLight
            return UIColor(hue: accentHue, saturation: accentSat, brightness: b, alpha: 1)
        })

        return MusicColorTheme(
            cardGradient: cardGradient,
            artworkGradient: artworkGradient,
            accent: accentColor
        )
    }
}
