import Foundation
import CoreLocation

extension Types.PrayerTimes {
    struct PrayerTimesLocation: Identifiable {
        let id = UUID()
        let city: String
        let coordinate: CLLocationCoordinate2D
        let country: String?
        let administrativeArea: String?
        let locality: String?
        let countryCode: String?
    }
}
