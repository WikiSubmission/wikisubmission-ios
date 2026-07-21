import ActivityKit
import Foundation

/// Attributes for the salat countdown Live Activity.
///
/// One Activity is created per prayer window (current prayer -> next prayer).
/// Everything fixed for the lifetime of a window lives here; only the color
/// phase travels in `ContentState`, so push payloads stay tiny and the visual
/// design is resolved entirely on-device (Dark/Light included).
struct SalatActivityAttributes: ActivityAttributes {

    /// The dynamic part of the Activity. Sent by local updates while the app
    /// is foregrounded and, later, by APNs `liveactivity` pushes.
    struct ContentState: Codable, Hashable {
        /// Palette anchor identifier, e.g. "day.rh6" or "night.nh4".
        /// Resolved against `SalatPalette.anchors` at render time.
        var phaseId: String

        /// 0...1 position between this anchor and the next one.
        /// The renderer lerps hue, saturation, and lightness with this value.
        var phaseProgress: Double
    }

    /// Human-readable location, e.g. "Melbourne, VIC".
    var locationName: String

    /// IANA timezone identifier from the prayer times API response. Kept for
    /// formatting; prayer math never uses `TimeZone.current`.
    var timezoneId: String

    /// Raw `PrayerName` value of the prayer that opened this window.
    var currentPrayer: String

    /// Raw `PrayerName` value of the prayer this window counts down to.
    var nextPrayer: String

    /// English display name for `nextPrayer` (e.g. "Sunset"), precomputed so
    /// the extension does not depend on the app's prayer types.
    var nextPrayerEnglish: String

    /// Instant the current prayer window opened.
    var windowStart: Date

    /// Instant of the next prayer; the countdown target.
    var windowEnd: Date
}
