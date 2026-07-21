import ActivityKit
import Foundation
import Defaults

/// Owns the salat countdown Live Activity lifecycle.
///
/// Fixes every failure mode of the October 2025 implementation:
/// - requests with `pushType: .token` so background push updates are possible
/// - re-attaches to a surviving Activity after app relaunch
/// - sets `staleDate` on every update
/// - drives perceptually-thinned color keyframes locally while the app is
///   foregrounded (pushes cover the backgrounded case once the server job
///   lands; tokens are already synced to the registry from here)
/// - never evaluates wall-clock time inside the extension views
@MainActor
final class SalatLiveActivityManager {

    static let shared = SalatLiveActivityManager()

    /// The Activity currently owned by this process, if any.
    private var activity: Activity<SalatActivityAttributes>?

    /// Long-running task applying scheduled keyframes while foregrounded.
    private var driveTask: Task<Void, Never>?

    /// Observer for the current Activity's per-activity push token.
    private var activityTokenTask: Task<Void, Never>?

    /// Observer for the app-wide push-to-start token stream.
    private var pushToStartTask: Task<Void, Never>?

    private init() {}

    // MARK: Entry points

    /// One-time startup wiring: observe push-to-start tokens and reconcile
    /// any Activity that survived a previous app run.
    func bootstrap() {
        observePushToStartTokens()
        Task { await ensureActivity() }
    }

    /// Reconcile the Live Activity with current preferences and prayer data.
    /// Safe to call often; it is idempotent for an unchanged window.
    func ensureActivity() async {
        guard Defaults[.prayer_live_activity] else {
            await endAll()
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("SalatLiveActivityManager: Live Activities disabled at system level")
            return
        }
        guard let data = Defaults[.prayer_times] else {
            await endAll()
            return
        }
        guard let day = buildDayTimes(from: data) else {
            print("SalatLiveActivityManager: could not derive day times")
            return
        }
        guard let window = currentWindow(in: day) else {
            print("SalatLiveActivityManager: could not bracket the current prayer window")
            return
        }

        let attributes = SalatActivityAttributes(
            locationName: data.location_string,
            timezoneId: data.local_timezone_id,
            currentPrayer: window.current.rawValue,
            nextPrayer: window.next.rawValue,
            nextPrayerEnglish: window.next.englishName,
            windowStart: window.start,
            windowEnd: window.end
        )

        // Re-attach to a surviving Activity for the same window rather than
        // churning it; end anything belonging to a stale window.
        if let existing = Activity<SalatActivityAttributes>.activities.first(where: { $0.attributes.windowEnd == window.end }) {
            adopt(existing)
        } else {
            for stale in Activity<SalatActivityAttributes>.activities {
                await stale.end(nil, dismissalPolicy: .immediate)
            }
            requestActivity(attributes: attributes, day: day)
        }

        startDriving(day: day, window: window)
    }

    /// End every salat Activity owned by the app (toggle off / location
    /// removed).
    func endAll() async {
        driveTask?.cancel()
        driveTask = nil
        activityTokenTask?.cancel()
        activityTokenTask = nil
        for a in Activity<SalatActivityAttributes>.activities {
            await a.end(nil, dismissalPolicy: .immediate)
        }
        activity = nil
    }

    // MARK: Activity lifecycle

    /// Request a fresh Activity for the current window with a push token so
    /// the server can update it once the pusher job exists.
    private func requestActivity(attributes: SalatActivityAttributes, day: SalatDayTimes) {
        let now = Date()
        let phase = SalatKeyframeScheduler.phase(at: now, in: day)
        let state = SalatActivityAttributes.ContentState(
            phaseId: phase.phaseId,
            phaseProgress: phase.progress
        )
        let content = ActivityContent(
            state: state,
            staleDate: now.addingTimeInterval(45 * 60),
            relevanceScore: SalatKeyframeScheduler.relevance(at: now, in: day)
        )

        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            adopt(newActivity)
            print("SalatLiveActivityManager: started activity \(newActivity.id) for window ending \(attributes.windowEnd)")
        } catch {
            print("SalatLiveActivityManager: failed to start activity: \(error)")
        }
    }

    /// Take ownership of an Activity and begin observing its push token.
    private func adopt(_ adopted: Activity<SalatActivityAttributes>) {
        activity = adopted
        activityTokenTask?.cancel()
        activityTokenTask = Task { [weak self] in
            for await tokenData in adopted.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    Defaults[.live_activity_push_token] = token
                }
                print("SalatLiveActivityManager: activity push token updated")
                try? await NotificationManager.shared.syncLiveActivitiesRegistry()
                _ = self // retain shape; observation ends with the activity
            }
        }
    }

    /// Observe the app-wide push-to-start token stream so the server can
    /// chain windows without the app opening (iOS 17.2+ API; floor is 18).
    private func observePushToStartTokens() {
        guard pushToStartTask == nil else { return }
        pushToStartTask = Task {
            for await tokenData in Activity<SalatActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    Defaults[.live_activity_push_to_start_token] = token
                }
                print("SalatLiveActivityManager: push-to-start token updated")
                try? await NotificationManager.shared.syncLiveActivitiesRegistry()
            }
        }
    }

    // MARK: Local keyframe driving

    /// Apply scheduled color keyframes while the process is alive. Sleeps to
    /// each fire date, updates, and rolls into the next window at the end.
    /// Suspension in the background is fine: the next foreground (or, later,
    /// a server push) catches the color up.
    private func startDriving(day: SalatDayTimes, window: (current: PrayerName, next: PrayerName, start: Date, end: Date)) {
        driveTask?.cancel()
        driveTask = Task { [weak self] in
            guard let self else { return }

            let upcoming = SalatKeyframeScheduler.keyframes(for: day)
                .filter { $0.fireDate > Date() && $0.fireDate <= window.end }

            // Apply the current state immediately so a re-attached Activity
            // is corrected the moment the app opens.
            await self.apply(phase: SalatKeyframeScheduler.phase(at: Date(), in: day), day: day, successorFire: upcoming.first?.fireDate ?? window.end)

            for kf in upcoming {
                let delay = kf.fireDate.timeIntervalSinceNow
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                guard !Task.isCancelled else { return }
                await self.apply(keyframe: kf)
            }

            // Window over: roll into the next one.
            let tail = window.end.timeIntervalSinceNow
            if tail > 0 {
                try? await Task.sleep(nanoseconds: UInt64(tail * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            await self.ensureActivity()
        }
    }

    /// Update the Activity with an ad-hoc phase (used for the immediate
    /// correction on foreground).
    private func apply(phase: (phaseId: String, progress: Double), day: SalatDayTimes, successorFire: Date) async {
        guard let activity else { return }
        let state = SalatActivityAttributes.ContentState(phaseId: phase.phaseId, phaseProgress: phase.progress)
        let content = ActivityContent(
            state: state,
            staleDate: successorFire.addingTimeInterval(30 * 60),
            relevanceScore: SalatKeyframeScheduler.relevance(at: Date(), in: day)
        )
        await activity.update(content)
    }

    /// Update the Activity with a scheduled keyframe.
    private func apply(keyframe: ScheduledKeyframe) async {
        guard let activity else { return }
        let state = SalatActivityAttributes.ContentState(phaseId: keyframe.phaseId, phaseProgress: keyframe.phaseProgress)
        let content = ActivityContent(
            state: state,
            staleDate: keyframe.staleDate,
            relevanceScore: keyframe.relevanceScore
        )
        await activity.update(content)
    }

    // MARK: Prayer data mapping

    /// Map the cached API response into pure `SalatDayTimes`. Handles the
    /// pre-fajr case by shifting today's cycle back one day (sub-minute drift
    /// per day; imperceptible in color and irrelevant to the countdown, whose
    /// target comes from the real times).
    private func buildDayTimes(from data: PrayerAPIResponse) -> SalatDayTimes? {
        let tz = SalatClock.timeZone(identifier: data.local_timezone_id)
        let now = Date()

        /// Resolve one prayer's instant on a given calendar day.
        func instant(_ prayer: PrayerName, times: PrayerTimes, day: Date) -> Date? {
            SalatClock.date(fromTimeString: times[prayer], onDay: day, timeZone: tz)
        }

        /// Build a full cycle from a schedule day and the following day's
        /// fajr, falling back to +24h when the schedule runs out.
        func cycle(today: Date, todayTimes: PrayerTimes, tomorrowFajr: Date?) -> SalatDayTimes? {
            guard
                let fajr = instant(.fajr, times: todayTimes, day: today),
                let sunrise = instant(.sunrise, times: todayTimes, day: today),
                let dhuhr = instant(.dhuhr, times: todayTimes, day: today),
                let asr = instant(.asr, times: todayTimes, day: today),
                let maghrib = instant(.maghrib, times: todayTimes, day: today),
                let isha = instant(.isha, times: todayTimes, day: today)
            else { return nil }
            return SalatDayTimes(
                fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr,
                maghrib: maghrib, isha: isha,
                nextFajr: tomorrowFajr ?? fajr.addingTimeInterval(86_400)
            )
        }

        // Locate today (and tomorrow) in the 30-day schedule; fall back to
        // the response's top-level `times` if the schedule is empty.
        let calendar = Calendar.current
        let todayIndex = data.schedule.firstIndex { calendar.isDate($0.date, inSameDayAs: now) }

        var day: SalatDayTimes?
        if let i = todayIndex {
            let tomorrowFajr: Date? = i + 1 < data.schedule.count
                ? instant(.fajr, times: data.schedule[i + 1].times, day: data.schedule[i + 1].date)
                : nil
            day = cycle(today: data.schedule[i].date, todayTimes: data.schedule[i].times, tomorrowFajr: tomorrowFajr)
        } else {
            day = cycle(today: now, todayTimes: data.times, tomorrowFajr: nil)
        }

        guard var resolved = day else { return nil }

        // Pre-fajr: the live cycle is yesterday's, approximated by -24h.
        if now < resolved.fajr {
            resolved = SalatDayTimes(
                fajr: resolved.fajr.addingTimeInterval(-86_400),
                sunrise: resolved.sunrise.addingTimeInterval(-86_400),
                dhuhr: resolved.dhuhr.addingTimeInterval(-86_400),
                asr: resolved.asr.addingTimeInterval(-86_400),
                maghrib: resolved.maghrib.addingTimeInterval(-86_400),
                isha: resolved.isha.addingTimeInterval(-86_400),
                nextFajr: resolved.fajr
            )
        }
        return resolved
    }

    /// Bracket `Date()` between two consecutive prayer events in the cycle.
    private func currentWindow(in day: SalatDayTimes) -> (current: PrayerName, next: PrayerName, start: Date, end: Date)? {
        let ordered: [(PrayerName, Date)] = [
            (.fajr, day.fajr), (.sunrise, day.sunrise), (.dhuhr, day.dhuhr),
            (.asr, day.asr), (.maghrib, day.maghrib), (.isha, day.isha),
            (.fajr, day.nextFajr)
        ]
        let now = Date()

        for i in 0..<(ordered.count - 1) {
            let (currentName, start) = ordered[i]
            let (nextName, end) = ordered[i + 1]
            if now >= start && now < end && end > start {
                return (currentName, nextName, start, end)
            }
        }
        return nil
    }
}
