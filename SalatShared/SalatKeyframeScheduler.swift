import Foundation

// MARK: - SalatDayTimes

/// The six prayer instants for one solar cycle plus the next day's fajr,
/// which closes the night arc. Pure `Date` values; all string parsing happens
/// upstream in `SalatClock`.
struct SalatDayTimes {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let nextFajr: Date

    /// Prayer boundary instants in order, used for relevance scoring and
    /// forced keyframes.
    var prayerBoundaries: [Date] {
        [fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr]
    }
}

// MARK: - ScheduledKeyframe

/// One planned Live Activity content update.
struct ScheduledKeyframe {
    /// When the update should be applied (or pushed).
    let fireDate: Date
    /// Palette anchor segment active at `fireDate`.
    let phaseId: String
    /// 0...1 position within that segment at `fireDate`.
    let phaseProgress: Double
    /// When this content should be considered stale if no successor arrives.
    let staleDate: Date
    /// 0...100 relevance, rising as the next prayer approaches.
    let relevanceScore: Double
}

// MARK: - SalatKeyframeScheduler

/// Turns one day's prayer times into a thinned schedule of color keyframes.
///
/// Fixed-cadence updates (e.g. every 15 minutes) are rejected by design: they
/// spend the ActivityKit update budget on imperceptible night-time steps.
/// Instead the interpolated curve is sampled densely and thinned by
/// perceptual distance, which clusters updates around sunrise and sunset and
/// spreads them out where only lightness crawls.
enum SalatKeyframeScheduler {

    /// Perceptual step between consecutive emitted keyframes (OKLab units).
    /// Tuned to land around 22-34 keyframes per day at temperate latitudes.
    static let perceptualStepThreshold: Double = 0.030

    /// Hard ceiling per day; the threshold self-raises to respect it.
    static let maximumKeyframesPerDay = 40

    /// Anchor ids paired with their instants for a given day. Piecewise
    /// pinned to the app's actual prayer times (rh6 = dhuhr, rh9 = asr) so
    /// the color cycle never disagrees with the numbers the user sees.
    static func anchorSchedule(for day: SalatDayTimes) -> [(id: String, date: Date)] {
        /// Linear interpolation between two dates.
        func lerp(_ a: Date, _ b: Date, _ t: Double) -> Date {
            a.addingTimeInterval(b.timeIntervalSince(a) * t)
        }
        /// Night hour instant: maghrib -> next fajr split into 12 NH.
        func nh(_ n: Double) -> Date {
            lerp(day.maghrib, day.nextFajr, n / 12)
        }

        return [
            ("night.nh12", day.fajr),
            ("day.rh0",    day.sunrise),
            ("day.rh2",    lerp(day.sunrise, day.dhuhr, 2 / 6)),
            ("day.rh4",    lerp(day.sunrise, day.dhuhr, 4 / 6)),
            ("day.rh6",    day.dhuhr),
            ("day.rh8",    lerp(day.dhuhr, day.asr, 2 / 3)),
            ("day.rh9",    day.asr),
            ("day.rh11",   lerp(day.asr, day.maghrib, 2 / 3)),
            ("day.rh12",   day.maghrib),
            ("night.nh0",  day.maghrib),
            ("night.nh1",  nh(1)),
            ("night.nh4",  nh(4)),
            ("night.nh6",  nh(6)),
            ("night.nh8",  nh(8)),
            ("night.nh11", nh(11)),
        ]
    }

    /// The phase segment and progress at an arbitrary instant within the
    /// cycle. Instants before fajr clamp to the cycle start; instants past
    /// next fajr clamp to the final segment's end.
    static func phase(at instant: Date, in day: SalatDayTimes) -> (phaseId: String, progress: Double) {
        let schedule = anchorSchedule(for: day)

        // Find the last anchor at or before the instant.
        var currentIndex = 0
        for (i, entry) in schedule.enumerated() where entry.date <= instant {
            currentIndex = i
        }

        let segmentStart = schedule[currentIndex].date
        let segmentEnd = currentIndex + 1 < schedule.count ? schedule[currentIndex + 1].date : day.nextFajr
        let duration = segmentEnd.timeIntervalSince(segmentStart)

        // Zero-length segments exist by construction (rh12 and nh0 share the
        // maghrib instant); report them as fully elapsed.
        guard duration > 0 else {
            return (schedule[currentIndex].id, 1)
        }

        let t = instant.timeIntervalSince(segmentStart) / duration
        return (schedule[currentIndex].id, min(max(t, 0), 1))
    }

    /// The thinned keyframe schedule for one day, in fire order.
    static func keyframes(for day: SalatDayTimes) -> [ScheduledKeyframe] {
        var threshold = perceptualStepThreshold

        // Self-raise the threshold until the schedule fits the daily cap.
        for _ in 0..<6 {
            let result = keyframes(for: day, threshold: threshold)
            if result.count <= maximumKeyframesPerDay {
                return result
            }
            threshold *= 1.3
        }
        return keyframes(for: day, threshold: threshold)
    }

    /// Schedule generation at a specific perceptual threshold.
    private static func keyframes(for day: SalatDayTimes, threshold: Double) -> [ScheduledKeyframe] {
        let schedule = anchorSchedule(for: day)
        let sampleStep: TimeInterval = 60

        // Force keyframes at every prayer boundary: the countdown target and
        // labels change there regardless of color delta.
        let forcedDates = Set(day.prayerBoundaries.map { $0.timeIntervalSinceReferenceDate })

        var emitted: [(date: Date, phaseId: String, progress: Double)] = []
        var lastEmittedHSL: SalatHSL?

        /// Emit one keyframe and remember its color for thinning.
        func emit(_ date: Date) {
            let p = phase(at: date, in: day)
            let (hsl, _) = SalatPalette.state(phaseId: p.phaseId, progress: p.progress)
            emitted.append((date, p.phaseId, p.progress))
            lastEmittedHSL = hsl
        }

        emit(day.fajr)

        // Walk each anchor segment, sampling every minute and emitting only
        // when the perceptual delta (in the darker of the two appearances,
        // where steps are most visible against OLED black) exceeds threshold.
        for i in 0..<schedule.count {
            let start = schedule[i].date
            let end = i + 1 < schedule.count ? schedule[i + 1].date : day.nextFajr
            guard end > start else { continue }

            var t = start.addingTimeInterval(sampleStep)
            while t < end {
                let p = phase(at: t, in: day)
                let (hsl, _) = SalatPalette.state(phaseId: p.phaseId, progress: p.progress)

                let isForced = forcedDates.contains(t.timeIntervalSinceReferenceDate)
                let farEnough = lastEmittedHSL.map {
                    max(
                        SalatPalette.perceptualDistance($0, hsl, dark: true),
                        SalatPalette.perceptualDistance($0, hsl, dark: false)
                    ) >= threshold
                } ?? true

                if isForced || farEnough {
                    emit(t)
                }
                t = t.addingTimeInterval(sampleStep)
            }

            // Segment boundaries that are prayer instants always emit.
            if forcedDates.contains(end.timeIntervalSinceReferenceDate), end < day.nextFajr {
                emit(end)
            }
        }

        // Assemble: staleDate points past the successor with a grace margin,
        // relevance ramps up over the final two hours before each prayer.
        return emitted.enumerated().map { i, kf in
            let successor = i + 1 < emitted.count ? emitted[i + 1].date : day.nextFajr
            let staleDate = successor.addingTimeInterval(30 * 60)
            return ScheduledKeyframe(
                fireDate: kf.date,
                phaseId: kf.phaseId,
                phaseProgress: kf.progress,
                staleDate: staleDate,
                relevanceScore: relevance(at: kf.date, in: day)
            )
        }
    }

    /// Relevance 0...100 for the system's Activity ranking: flat at 25 for
    /// most of a window, climbing linearly through the last 120 minutes
    /// before the next prayer boundary.
    static func relevance(at instant: Date, in day: SalatDayTimes) -> Double {
        guard let next = day.prayerBoundaries.first(where: { $0 > instant }) else {
            return 25
        }
        let minutes = next.timeIntervalSince(instant) / 60
        guard minutes < 120 else { return 25 }
        return 25 + (120 - minutes) / 120 * 75
    }
}
