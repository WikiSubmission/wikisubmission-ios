# Salat Live Activity Rebuild: Architecture Spec

Status: planning pass complete, ready for implementation handoff.
Scope: this repo (iOS app) plus a defined server contract for the existing WS push infrastructure.
Implementer: Claude Sonnet or Codex, per task chunks in section 9. Final review pass against this document before commit.

House rules for all downstream work: comment every function, README.md per new module, never nano, use env vars over hardcoded paths where relevant, Conventional Commits with no co-author trailer, no AI-cliche phrasing in user-facing copy.

---

## 0. Platform decision (supersedes "iOS 17 floor" in the original brief)

The app target already ships with `IPHONEOS_DEPLOYMENT_TARGET = 18.0`. A widget extension cannot reach a device the host app will not install on, so an iOS 17 extension floor buys nothing. Decision:

- Extension and all Live Activity code target iOS 18.0 minimum, matching the app.
- iOS 26/27 Liquid Glass presentation is a progressive enhancement behind `if #available`, with the iOS 18 rendering as the designed baseline (not a degraded afterthought).
- This unlocks, at no compatibility cost: push-to-start tokens (17.2+), APNs broadcast channels for Live Activities (18.0+), relevance scores, and stale presentation.

If a future decision lowers the app itself to iOS 17, nothing in this spec breaks except broadcast channels; per-device pushes remain as fallback (section 6).

## 1. What the old implementation got wrong (and what to keep)

Reviewed at `~/Documents/repo/wikisubmission-ios` (Oct 2025).

Discard, with reasons:

1. `pushType: nil` in `Activity.request`. The Activity was only ever updated when the app happened to call `updateOrStartLiveActivity()` in the foreground. Background color drift was impossible. The rebuild is push-driven.
2. `Date()` evaluated inside the Live Activity view body (`progressiveGradientBackground`). Live Activity views render once per content update; the "progressive" gradient froze at render time. Never sample wall-clock time in the view for anything except the native `Text(timerInterval:)` / `ProgressView(timerInterval:)` types, which are the only self-advancing elements.
3. Prayer times passed as display strings (`"h:mm a"`) and re-parsed with `DateFormatter` in three separate places, with day-rollover guessing and locale pinning. The rebuild passes epoch `Date`s in `ContentState` and formats at the edge only.
4. `staleDate: nil`. Activities could show hours-old state with no visual signal. Every update in the rebuild sets `staleDate` to the next expected keyframe time plus a grace margin.
5. No re-attachment: `currentActivity` was an in-memory var, so an app relaunch orphaned the running Activity. The rebuild enumerates `Activity<SalatActivityAttributes>.activities` on launch and re-observes.
6. Duplicate attributes: `PrayerTimesAttributes` in `SharedModels.swift` was dead code shadowing the real `PrayerTimesWidgetAttributes`. One attributes type, one file, shared target membership, nothing else.
7. Widget read `Defaults[.prayer_times]` from the standard suite while the extension entitlement declared `group.la.tfp.quraniclabs.prayertimes`. Different processes, different suites: the extension likely read nil outside debug. The rebuild routes all shared state through one App Group suite explicitly (section 7).
8. The blue "midnight to navy" palette: arbitrary, replaced wholesale by the solar hue model.
9. Old App Group id `group.la.tfp.quraniclabs.prayertimes` does not match the current bundle id. New id: `group.com.motoread.QuranicLabs` (confirm team portal availability before scaffolding).

Keep:

1. The general Dynamic Island region layout (leading = current, trailing = next, bottom = countdown) reads well; rebuild restyles it rather than reinventing it.
2. The glyph-per-prayer concept and several concrete symbol choices (`sunrise.fill`, `sunset.fill`, `sun.max.fill`).
3. The luminance-based text color flip (WCAG-style weighted luminance check); generalize it into the palette module instead of ad hoc math in the view.

## 2. Source of truth for times

Do not reinvent solar or prayer time calculation. `PrayerManager.fetchTimes()` already caches a `PrayerAPIResponse` in `Defaults[.prayer_times]` containing:

- `times` for today (fajr, sunrise, dhuhr, asr, maghrib, isha) as local time strings
- `schedule`: 30 days of per-day `PrayerTimes` with real `Date` values
- `local_timezone_id`, coordinates, location string

The 30-day `schedule` is the anchor. The keyframe scheduler (section 4) consumes `schedule` plus `local_timezone_id` and can compute the full color curve for days ahead entirely on device. The server needs the same times, which it already has (it sends prayer alert pushes from the registry today).

Parsing rule: convert each schedule day's time strings to `Date` once, in one utility (`SalatClock`), using `local_timezone_id`, never `TimeZone.current`. The user's saved location may not be the device timezone.

## 3. Color model

### 3.1 Coordinate system

All keyframes are defined in HSL-like terms (hue degrees, saturation 0-1, lightness 0-1) with two lightness values per keyframe: `lightModeL` and `darkModeL`. Hue and saturation are shared between modes; only lightness differs. Rendered via `UIColor { trait in ... }` dynamic providers so Dark/Light switching is free and automatic, including inside the extension.

Interpolation between keyframes happens in this same space with shortest-path hue wrapping (350 to 10 degrees crosses 0, not 340 degrees the long way). Near the noon keyframe saturation approaches 0 and hue becomes meaningless; the interpolator must lerp saturation first and hold the last meaningful hue, never spin hue through the desaturated zone.

### 3.2 Time axes

Relative hours, computed per day from the schedule:

- Day arc: RH0 = sunrise, RH6 = solar noon (dhuhr), RH9 = asr, RH12 = maghrib. One RH = (maghrib - sunrise) / 12.
- Night arc: NH0 = maghrib, NH12 = next day's fajr. One NH = (next fajr - maghrib) / 12. Three watches of 4 NH each. Solar midnight = NH6.

### 3.3 Keyframe table (the spec; implementer refines lightness values against device renders, not hues)

Day arc (hue sweeps, lightness high):

| Marker | Time | Hue | Sat | L (light mode) | L (dark mode) |
|---|---|---|---|---|---|
| day.rh0 | sunrise | 30 | 0.85 | 0.62 | 0.38 |
| day.rh2 | mid-morning | 45 | 0.80 | 0.68 | 0.42 |
| day.rh4 | late morning | 52 | 0.60 | 0.76 | 0.46 |
| day.rh6 | solar noon | 50 (inert) | 0.06 | 0.93 | 0.52 |
| day.rh8 | early afternoon | 50 | 0.55 | 0.78 | 0.46 |
| day.rh9 | asr | 45 | 0.75 | 0.70 | 0.43 |
| day.rh11 | approaching maghrib | 30 | 0.85 | 0.60 | 0.38 |
| day.rh12 | maghrib | 12 | 0.90 | 0.52 | 0.34 |

Night arc (hue nearly locked, lightness sweeps):

| Marker | Time | Hue | Sat | L (light mode) | L (dark mode) |
|---|---|---|---|---|---|
| night.nh0 | just after maghrib | 12 | 0.85 | 0.45 | 0.30 |
| night.nh1 | settled red | 0 | 0.85 | 0.38 | 0.24 |
| night.nh4 | first watch end | 0 | 0.80 | 0.28 | 0.16 |
| night.nh6 | solar midnight | 0 | 0.75 | 0.20 | 0.10 |
| night.nh8 | second watch end | 355 | 0.75 | 0.26 | 0.15 |
| night.nh11 | approaching fajr | 350 | 0.80 | 0.36 | 0.22 |
| night.nh12 | fajr | 348 | 0.75 | 0.44 | 0.28 |

Design intent encoded above, verify these survive implementation:

- Directionality: dusk sits at pure 0 hue, dawn leans magenta (348-355). Post-sunset orange (hue 12-30 falling) and pre-sunrise (348-350 rising) are distinguishable even at similar lightness. This is the primary "which way is time moving" cue; the glyph is the secondary cue.
- Solar midnight in Dark Mode goes near-black on purpose (L 0.10). In Light Mode it must not: L 0.20 keeps it legibly "darkest red," not a dead panel.
- Noon in Light Mode is near-white parchment; in Dark Mode noon is a lifted desaturated warm gray (L 0.52), never white, so a noon lock-screen glance at night brightness does not blind.

### 3.4 Accent derivation (computed, never hand-picked per view)

`AccentPalette(from mainHue:sat:l:)` in the shared palette module:

- 3 accent slots needed: triadic, main hue +120 and -120, saturation clamped to 0.55-0.7, lightness offset for contrast against the main surface.
- 2 accent slots: complementary, main hue +180.
- Saturation guard: if main saturation < 0.15 (the noon zone), all accents collapse to neutral grays derived from the main lightness. Hue math at zero saturation produces garbage; this guard is mandatory and unit-tested.
- Text/foreground: weighted-luminance flip (from the old code, generalized) with minimum contrast ratio 4.5:1 against the resolved surface; if the flip result fails, push lightness until it passes.

### 3.5 Glyph mapping (accessibility backstop, monochrome-safe)

| State | SF Symbol | Note |
|---|---|---|
| pre-dawn (nh8-nh12) | `moon.haze.fill` | "night thinning" |
| fajr window | `sun.haze.fill` | kept from old code |
| sunrise | `sunrise.fill` | arrow encodes direction |
| morning (rh0-rh5) | `sun.min.fill` | |
| noon (rh5-rh7) | `sun.max.fill` | |
| afternoon (rh7-rh9) | `sun.min.fill` | paired with falling hue |
| asr (rh9-rh11) | `sun.and.horizon.fill` | |
| maghrib | `sunset.fill` | arrow encodes direction |
| first watch (nh0-nh4) | `moon.fill` | |
| middle watch (nh4-nh8) | `moon.stars.fill` | solar midnight watch |
| last watch (nh8-nh12) | `moon.haze.fill` | merges into pre-dawn |

All render as template images, so they survive monochrome, Smart Invert, and colorblind conditions. Do not use `moonphase.*` symbols: they assert a literal lunar phase the sky will contradict.

## 4. Keyframe scheduler

Pure, deterministic, unit-testable module (`SalatKeyframeScheduler`), shared between the app and (as a reference implementation) the server job.

Input: one `PrayerScheduleDay` (+ next day's fajr), timezone id.
Output: `[ScheduledKeyframe]` for the 24h cycle, where `ScheduledKeyframe = (fireDate, phaseId, resolvedHSL, staleDate, relevanceScore)`.

Algorithm:

1. Compute RH/NH anchors per section 3.2.
2. Densely sample the interpolated curve (1-minute steps).
3. Thin by perceptual delta: emit a keyframe only when the color distance from the last emitted keyframe exceeds a threshold (approximate ΔE via OKLab distance, threshold tuned so output lands at 22-34 keyframes per day). This naturally clusters keyframes around sunrise and sunset (fast hue movement) and spaces them out across midday and the dead of night (slow lightness drift), which is exactly where battery and push budget should be spent and saved respectively.
4. Force-include keyframes at every prayer boundary regardless of delta (the state text changes there anyway).
5. Cap the schedule at a hard maximum (40/day) as a safety valve.

Fixed 15-minute cadence is explicitly rejected: 96 updates/day, most of them imperceptible at night, blowing the ActivityKit update budget for zero visual gain. Perceptual thinning delivers smoother-looking transitions where the eye can see them at roughly a quarter of the update volume.

## 5. ActivityKit shape

One Activity per prayer window (current prayer to next prayer), not one per day. Rationale: ActivityKit caps an Activity at 8 hours active; windows between consecutive prayers are comfortably under that in almost all cases (isha to fajr at extreme latitudes is the exception, handled by chaining). Per-window activities also make the static/dynamic split clean.

```swift
struct SalatActivityAttributes: ActivityAttributes {
    // Static for the lifetime of one prayer window.
    var locationName: String        // display string, e.g. "Melbourne, VIC"
    var timezoneId: String          // IANA id from the API response
    var currentPrayer: String       // PrayerName.rawValue at window start
    var nextPrayer: String          // PrayerName.rawValue
    var windowStart: Date           // current prayer time
    var windowEnd: Date             // next prayer time (countdown target)

    struct ContentState: Codable, Hashable {
        var phaseId: String         // e.g. "day.rh6", "night.nh3" -> palette lookup
        var phaseProgress: Double   // 0-1 between this phase anchor and the next, client lerps at render
        var hueOverride: Double?    // escape hatch: server-forced hue, normally nil
        var isStalePreview: Bool    // reserved, default false
    }
}
```

Deliberate choices:

- Color is NOT in `ContentState` as RGB. The client resolves `phaseId + phaseProgress` through the compiled-in palette (section 3), which carries both Light and Dark lightness curves. Payloads stay tiny, dark mode costs the server nothing, and every design iteration is an app update rather than a server deploy.
- The countdown target (`windowEnd`) is static in Attributes; the countdown itself is `Text(timerInterval: windowStart...windowEnd, countsDown: true)` and the progress ring is `ProgressView(timerInterval:)`. These are the only elements that animate between pushes, and they animate for free.
- Every update sets `staleDate = nextKeyframe.fireDate + 30 min`. The stale presentation dims saturation and shows a subtle refresh glyph, honest about drift instead of lying in old colors.

Lifecycle manager (`SalatLiveActivityManager`, app target, replaces the old manager):

- `ensureActivity()` on app foreground and after each successful `fetchTimes()`: re-attach to `Activity.activities` if one exists for the current window, else request one with `pushType: .token`.
- Observe `pushTokenUpdates` per activity and `pushToStartTokenUpdates` (iOS 17.2+ API, we are on 18) at app level; sync both to the server registry (section 6).
- End the window's activity with `dismissalPolicy: .after(windowEnd + 10 min)`; the server push-to-starts the next window's activity so the chain survives without the app opening.
- Local update path: while the app is foregrounded, drive keyframes from the scheduler directly (no push needed); pushes exist for the backgrounded case.

## 6. Server contract (existing push infra, extended, not replaced)

The Supabase `internal` schema already has per-feature registry tables keyed on `device_token`, and a pusher at `push-notifications.wikisubmission.org` that sends prayer alerts. Extend, same pattern:

New table `ws_push_notifications_registry_live_activities`:

| column | type | note |
|---|---|---|
| device_token | text PK, FK to users | same convention as other registries |
| user_id | uuid | |
| enabled | bool | mirrors an in-app toggle |
| location | text | same value the prayer-times registry uses |
| push_to_start_token | text nullable | from `pushToStartTokenUpdates` |
| activity_push_token | text nullable | current window's activity token |
| afternoon_midpoint_method | bool | keyframe times must match what the user sees |
| updated_at | timestamptz | |

Client sync: add a `syncPushNotificationsRegistryLiveActivities` sibling in `NotificationManager`, upsert on token change and toggle change, and fold it into the existing `sync()` task group.

Server job (WS infra repo, separate handoff to Hesham/Sarim or a dedicated session):

1. Per distinct `location` among enabled rows, compute the day's keyframe schedule (same algorithm as section 4; a reference JSON fixture generated by the Swift unit tests keeps the two implementations honest).
2. At each keyframe fire time, send an APNs `liveactivity` push with the `content-state` matching `ContentState` above, `event: update`, `timestamp`, and `relevance-score` rising as the prayer approaches.
3. Priority policy: `priority: 5` for cosmetic color keyframes, `priority: 10` only for prayer-boundary updates and window-chaining `start` events (these coincide with the alert pushes the server already sends, so the incremental cost is near zero).
4. Window chaining: at each prayer time, `event: start` via the stored push-to-start token for the new window with fresh Attributes.

Efficiency upgrade, recommended once basic per-device pushes work: APNs broadcast channels (iOS 18+). Devices subscribe to a channel per location; the server sends one push per location per keyframe instead of one per device. For any city with more than a handful of users this collapses the pusher's APNs volume by orders of magnitude. Dark/Light needs nothing special because color resolution is client-side. Keep per-device delivery for `start` events (push-to-start tokens are inherently per-device).

Add to the extension's Info.plist: `NSSupportsLiveActivitiesFrequentUpdates = YES` (raises the update budget; our worst day is ~40 updates).

## 7. New target scaffolding

- New Widget Extension target `SalatActivityExtension`, embedded in the app, iOS 18.0 deployment target.
- App Group `group.com.motoread.QuranicLabs` added to BOTH targets; all shared Defaults reads in the extension go through `UserDefaults(suiteName:)` explicitly (this is the bug class that sank the old widget, see 1.7).
- `NSSupportsLiveActivities = YES` in the app Info.plist, `NSSupportsLiveActivitiesFrequentUpdates = YES` in the extension.
- Fonts: bundle only `JetBrainsMono-Medium.ttf` (numerals, eyebrow labels) and `CormorantGaramond-Medium.ttf` (period name) into the extension with their own `UIAppFonts` entries; fall back to `.system(design: .serif)` / `.monospaced` if resolution fails. Do not drag all 15 font files into the extension.
- Shared source folder `QuranicLabs/Shared/Salat/` with target membership in both app and extension: `SalatActivityAttributes.swift`, `SalatPalette.swift`, `SalatKeyframeScheduler.swift`, `SalatClock.swift`, `AccentPalette.swift`. README.md in that folder describing the module per house rules.
- Deep link: `widgetURL(URL(string: "wikisubmission://prayer"))` on all presentations; the scheme and router already exist.

## 8. Presentation spec

Lock screen / banner:

- Full-bleed background: vertical gradient from the resolved keyframe color to a 12% darker variant of itself (self-derived, never a second hand-picked color).
- Leading: period glyph + small-caps period label (JetBrains Mono eyebrow style, tracking 2, mirroring `DS.Typography.eyebrow`).
- Center/trailing: next prayer English name in Cormorant, then `Text(timerInterval:)` countdown in mono.
- Thin `ProgressView(timerInterval:)` ring or bar tinted with accent slot 1; ring FILLS toward the next prayer (fill direction is the second "which way is time moving" cue after the dawn/dusk hue bias).
- Location string, eyebrow-small, accent slot 2.
- Exactly 2 accent slots on lock screen, so complementary derivation applies.

Dynamic Island:

- Compact leading: period glyph tinted with main color. Compact trailing: countdown, mono, `.frame(width: 50, alignment: .trailing)` kept from old code to stop jitter.
- Minimal: glyph only.
- Expanded: old code's region layout restyled with palette + typography above; bottom region carries the countdown and progress bar. Expanded uses 3 accent slots, so triadic derivation applies.

iOS 26/27 enhancement (`if #available(iOS 26, *)`): tint translucent glass layers with the keyframe color rather than filling opaque rectangles, keep everything functional identical below. No layout forks, tint treatment only.

Stale presentation (`context.isStale`): drop saturation 40%, show `arrow.trianglehead.2.clockwise` micro-glyph next to the countdown.

## 9. Task breakdown for Sonnet / Codex

Each task is one commit-sized chunk, Conventional Commits, no co-author trailer. Suggested types in brackets.

1. [feat] Scaffold `SalatActivityExtension` target, App Group on both targets, Info.plist keys, entitlements, font subset, empty `WidgetBundle`. Acceptance: app + extension build, a hardcoded placeholder Activity can be started from a debug button.
2. [feat] `SalatClock` + `SalatKeyframeScheduler` + `SalatPalette` + `AccentPalette` in `Shared/Salat/`, pure logic, no UI. Acceptance: unit tests covering RH/NH anchor math for a Melbourne summer day and winter day, hue wrap at 350-10, noon saturation guard, ΔE thinning output count 22-34, DST transition day, and a JSON fixture export of one day's schedule (server reference).
3. [feat] `SalatActivityAttributes` + `SalatLiveActivityManager`: request with `pushType: .token`, re-attach on launch, token observation streams, staleDate on every update, window end policy, local keyframe driving while foregrounded. Acceptance: activity survives app kill and relaunch; tokens logged.
4. [feat] Lock screen + Dynamic Island views per section 8, iOS 18 baseline only. Acceptance: previews for 6 representative phases (rh0, rh6, rh11, nh1, nh6, nh11) in both color schemes; text passes 4.5:1 in all 12 renders.
5. [feat] App integration: settings toggle "Prayer Live Activity" alongside the existing notification toggles, `NotificationManager` registry sync extension, `PrayerManager` hook after successful fetch, deep link verification.
6. [feat] iOS 26+ glass tint enhancement behind availability check.
7. [server, separate repo] Registry table migration + pusher job per section 6, validated against the JSON fixture from task 2. Broadcast channels as a follow-up once per-device delivery is verified.
8. [chore] QA pass: fresh install flow (no location), location change mid-window, timezone-differs-from-device case, airplane-mode staleness, 8h window cap behavior, Activity permission denied path.

Review pass (Fable, post-implementation) checks: no `Date()` in any extension view body outside `timerInterval` types, no `DateFormatter` string round-trips of prayer times, every shared-suite read explicit, every function commented, saturation guard test present, staleDate never nil.

## 10. Open items needing Stirling's sign-off

1. iOS 18 floor per section 0 (recommended; the alternative is lowering the whole app target to 17 and auditing every API in the app, for zero reachable users gained today).
2. App Group id `group.com.motoread.QuranicLabs` (portal availability to confirm).
3. Whether the server job lands in the existing pusher codebase or a new worker on marvin/neptr; the contract in section 6 is host-agnostic.
4. Exact lightness values in 3.3 are tuned-on-device numbers; the table is the starting point, not scripture. Hues and the directionality/magenta-bias rules ARE scripture.
