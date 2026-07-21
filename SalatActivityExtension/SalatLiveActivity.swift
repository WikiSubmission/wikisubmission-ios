import ActivityKit
import WidgetKit
import SwiftUI
import UIKit

// MARK: - Fonts

/// Serif display font with a graceful system fallback if the bundled ttf
/// fails to register in the extension for any reason.
func salatSerif(_ size: CGFloat) -> Font {
    if UIFont(name: "CormorantGaramond-Medium", size: size) != nil {
        return .custom("CormorantGaramond-Medium", size: size)
    }
    return .system(size: size, weight: .medium, design: .serif)
}

/// Mono numeral/eyebrow font with the same fallback strategy.
func salatMono(_ size: CGFloat) -> Font {
    if UIFont(name: "JetBrainsMono-Medium", size: size) != nil {
        return .custom("JetBrainsMono-Medium", size: size)
    }
    return .system(size: size, weight: .medium, design: .monospaced)
}

// MARK: - Widget configuration

/// The salat countdown Live Activity: color as the primary information
/// channel, glyph as the accessibility backstop, numerals as the backup.
struct SalatLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SalatActivityAttributes.self) { context in
            SalatLockScreenView(context: context)
                .widgetURL(URL(string: "wikisubmission://prayer"))
        } dynamicIsland: { context in
            // The Dynamic Island renders on hardware black regardless of the
            // system appearance, so everything resolves with dark lightness.
            let r = AccentPalette.resolve(
                phaseId: context.state.phaseId,
                progress: context.state.phaseProgress,
                dark: true,
                slots: 3
            )

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Image(systemName: r.symbol)
                            .font(.title3)
                            .foregroundStyle(r.surface)
                        Text(r.label)
                            .font(salatMono(9))
                            .tracking(1.6)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("NEXT")
                            .font(salatMono(9))
                            .tracking(1.6)
                            .foregroundStyle(.secondary)
                        Text(context.attributes.nextPrayerEnglish)
                            .font(salatSerif(18))
                            .foregroundStyle(.primary)
                        Text(context.attributes.windowEnd, style: .time)
                            .font(salatMono(10))
                            .foregroundStyle(r.accents[0])
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Self-advancing countdown; the only free animation.
                        Text(timerInterval: context.attributes.windowStart...context.attributes.windowEnd, countsDown: true)
                            .font(salatMono(22))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)

                        // Ring/bar FILLS toward the next prayer: the second
                        // directional cue after the dawn/dusk hue bias.
                        ProgressView(timerInterval: context.attributes.windowStart...context.attributes.windowEnd, countsDown: false)
                            .progressViewStyle(.linear)
                            .tint(r.accents[1])
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .saturation(context.isStale ? 0.5 : 1.0)
                }
            } compactLeading: {
                Image(systemName: r.symbol)
                    .font(.caption)
                    .foregroundStyle(r.surface)
            } compactTrailing: {
                Text(timerInterval: context.attributes.windowStart...context.attributes.windowEnd, countsDown: true)
                    .font(salatMono(11))
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
                    .foregroundStyle(r.surface)
            } minimal: {
                Image(systemName: r.symbol)
                    .font(.caption)
                    .foregroundStyle(r.surface)
            }
            .keylineTint(r.surface)
        }
    }
}

// MARK: - Lock screen presentation

/// Full-bleed lock screen / banner presentation. The background gradient is
/// the state; text confirms it.
struct SalatLockScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<SalatActivityAttributes>

    var body: some View {
        // Lock screen uses exactly 2 accent slots -> complementary derivation.
        let r = AccentPalette.resolve(
            phaseId: context.state.phaseId,
            progress: context.state.phaseProgress,
            dark: colorScheme == .dark,
            slots: 2
        )

        ZStack {
            // Surface -> self-derived deeper stop; never a second hand-picked
            // color.
            LinearGradient(
                colors: [r.surface, r.surfaceDeep],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    // Leading: period identity (glyph + tracked caps label).
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: r.symbol)
                                .font(.title3)
                            if context.isStale {
                                // Honest-drift marker when no fresh keyframe
                                // has arrived by the stale date.
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .font(.caption2)
                                    .foregroundStyle(r.inkMuted)
                            }
                        }
                        Text(r.label)
                            .font(salatMono(10))
                            .tracking(2)
                            .foregroundStyle(r.inkMuted)
                    }

                    Spacer()

                    // Trailing: the countdown target.
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.nextPrayerEnglish)
                            .font(salatSerif(24))
                        Text(timerInterval: context.attributes.windowStart...context.attributes.windowEnd, countsDown: true)
                            .font(salatMono(16))
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Progress fills toward the next prayer (directional cue).
                ProgressView(timerInterval: context.attributes.windowStart...context.attributes.windowEnd, countsDown: false)
                    .progressViewStyle(.linear)
                    .tint(r.accents[0])
                    .labelsHidden()

                HStack {
                    Text(context.attributes.locationName.uppercased())
                        .font(salatMono(9))
                        .tracking(1.8)
                        .foregroundStyle(r.inkMuted)
                    Spacer()
                    Text(context.attributes.windowEnd, style: .time)
                        .font(salatMono(9))
                        .foregroundStyle(r.inkMuted)
                }
            }
            .foregroundStyle(r.ink)
            .padding(14)
        }
        .saturation(context.isStale ? 0.6 : 1.0)
        .activityBackgroundTint(r.surface)
        .activitySystemActionForegroundColor(r.ink)
    }
}
