import Foundation

/// Timezone-correct parsing and combination of prayer time strings.
///
/// The prayer times API returns display strings ("5:59 am" style) plus an
/// IANA timezone id. The user's saved location may not match the device
/// timezone, so every conversion here goes through the location's timezone
/// explicitly. `TimeZone.current` is never used for prayer math.
enum SalatClock {

    /// Formats the API has been observed to emit, tried in order.
    private static let acceptedFormats = ["h:mm a", "hh:mm a", "HH:mm"]

    /// Resolve an IANA timezone id, falling back to the device timezone with
    /// a log line rather than failing the whole feature.
    static func timeZone(identifier: String) -> TimeZone {
        if let tz = TimeZone(identifier: identifier) {
            return tz
        }
        print("SalatClock: unknown timezone id '\(identifier)', falling back to device timezone")
        return TimeZone.current
    }

    /// Combine a time-of-day string with a calendar day into an absolute
    /// instant in the given timezone.
    ///
    /// - Parameters:
    ///   - timeString: e.g. "5:59 am", "12:15 PM", or "17:03".
    ///   - day: any instant on the target calendar day. Its year/month/day
    ///     are extracted with the device calendar (matching how the API's
    ///     schedule dates were decoded) and re-anchored in `timeZone`.
    ///   - timeZone: the location's timezone.
    static func date(fromTimeString timeString: String, onDay day: Date, timeZone: TimeZone) -> Date? {
        let cleaned = timeString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Parse the clock time. The formatter's own date component output is
        // discarded; only hour and minute are kept.
        var parsedTime: Date?
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        for format in acceptedFormats {
            formatter.dateFormat = format
            if let d = formatter.date(from: cleaned) {
                parsedTime = d
                break
            }
        }
        guard let parsedTime else {
            print("SalatClock: could not parse time string '\(timeString)'")
            return nil
        }

        // Extract h/m in the location timezone.
        var locationCalendar = Calendar(identifier: .gregorian)
        locationCalendar.timeZone = timeZone
        let hm = locationCalendar.dateComponents([.hour, .minute], from: parsedTime)

        // Extract y/m/d with the device calendar, because the schedule's
        // `date` values were decoded at device-timezone midnight.
        let deviceCalendar = Calendar.current
        var components = deviceCalendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hm.hour
        components.minute = hm.minute
        components.second = 0
        components.timeZone = timeZone

        return locationCalendar.date(from: components)
    }
}
