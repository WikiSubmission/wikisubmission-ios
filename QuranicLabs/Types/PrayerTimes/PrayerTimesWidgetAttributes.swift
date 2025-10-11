import ActivityKit
import Foundation

struct PrayerTimesWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentPrayerName: String
        var currentPrayerSymbol: String
        var nextPrayerName: String
        var nextPrayerTime: Date
        var nextPrayerSymbol: String
        var locationString: String
        var timePeriod: String
    }
}
