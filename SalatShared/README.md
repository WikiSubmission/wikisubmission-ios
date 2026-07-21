# SalatShared

Pure, dependency-free Swift shared between the QuranicLabs app target and the
SalatActivityExtension widget target. No SPM packages, no app types, no UIKit
state; everything here is deterministic and unit-testable.

## Files

- `SalatActivityAttributes.swift` - ActivityKit attributes/content state for
  the prayer countdown Live Activity. One Activity per prayer window; only
  the color phase (`phaseId` + `phaseProgress`) is dynamic.
- `SalatPalette.swift` - the solar color cycle. 15 ordered HSL anchors with
  separate Light/Dark lightness, shortest-path hue interpolation with a
  saturation guard at the desaturated noon keyframe, and OKLab perceptual
  distance used for keyframe thinning. Dusk settles at pure 0 degrees; dawn
  leans magenta (348-355) so pre-sunrise and post-sunset are distinguishable.
- `AccentPalette.swift` - derives every secondary color from the main
  keyframe: triadic for 3 slots, complementary for 2, neutral grays inside
  the noon saturation-guard zone, luminance-flipped ink with an editorial
  warm black/off-white pairing.
- `SalatKeyframeScheduler.swift` - turns one day's prayer times into a
  thinned update schedule (target 22-34/day, hard cap 40) with staleDate and
  relevance per keyframe. Anchors are piecewise pinned to the app's actual
  dhuhr/asr times so color never disagrees with the numbers.
- `SalatClock.swift` - timezone-correct parsing of the API's time strings.
  Never uses `TimeZone.current` for prayer math.

## Design intent

Color is the primary information channel; the countdown numerals are the
backup. See `LIVE_ACTIVITY_REBUILD_SPEC.md` at the repo root for the full
architecture, server contract, and review checklist.

## Server note

The keyframe scheduler doubles as the reference implementation for the push
server job (see spec section 6). Any change to anchors or thinning must be
mirrored there once the server side lands.
