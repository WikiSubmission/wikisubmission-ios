import Foundation
import Defaults

extension Utilities.System {
    static func migrationTasks() {
        // Prayer times: use new prayer-times-data keys.
        if let oldPrayerTimesData = UserDefaults.standard.data(forKey: "prayerTimesData") {
            if let encodedOldPrayerTimesData = try? JSONDecoder().decode(Types.PrayerTimes.PrayerTimesResponse.self, from: oldPrayerTimesData) {
                Defaults[.prayer_times] = encodedOldPrayerTimesData // assign to new key
                UserDefaults.standard.removeObject(forKey: "prayerTimesData") // remove old key (this won't run again)
            }
        }
        
        // Prayer times: use new prayer-times-location keys
        if let oldPrayerTimesLocationString = UserDefaults.standard.string(forKey: "prayer_time_location") {
            Defaults[.prayer_times_location] = oldPrayerTimesLocationString // assign to new key
            UserDefaults.standard.removeObject(forKey: "prayer_time_location") // remove old key (this won't run again)
        }
    }
}
