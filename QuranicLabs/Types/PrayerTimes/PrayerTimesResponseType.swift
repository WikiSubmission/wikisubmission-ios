import Foundation
import Defaults

extension Types.PrayerTimes {
    struct PrayerTimesResponse: Codable, Defaults.Serializable {
        let status_string: String
        let location_string: String
        let country: String
        let country_code: String
        let city: String
        let region: String
        let local_time: String
        let local_timezone: String
        let local_timezone_id: String
        let coordinates: Coordinates
        let times: Types.PrayerTimes.PrayerTimesResponseTimes
        let times_left: Types.PrayerTimes.PrayerTimesResponseTimes
        let current_prayer: Types.PrayerTimes.PrayerTypes
        let upcoming_prayer: Types.PrayerTimes.PrayerTypes
        let current_prayer_time_elapsed: String
        let upcoming_prayer_time_left: String

        struct Coordinates: Codable {
            let latitude: Double
            let longitude: Double
        }
    }
    
    enum PrayerTypes: String, Codable, CaseIterable {
        case fajr, dhuhr, asr, maghrib, isha, sunrise
    }
    
    struct PrayerTimesResponseTimes: Codable {
        let fajr: String
        let dhuhr: String
        let asr: String
        let maghrib: String
        let isha: String
        let sunrise: String
    }
}
