import Foundation
import SwiftUI
import Defaults

extension Utilities.PrayerTimes {
    class PrayerTimesManager: ObservableObject {
        static let shared = PrayerTimesManager()
        
        @Published var isLoading = false
                
        init() {
            Utilities.System.migrationTasks()
        }
        
        func fetchPrayerTimes(for location: String) {
            
            Defaults[.prayer_times_location] = location
            
            guard Utilities.System.NetworkMonitor.shared.hasInternet else { return }
            
            defer {
                Task {
                    try? await Utilities.Notifications.syncWithDatabase()
                }
            }
            
            isLoading = true
            let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location
            
            let useMidpointMethodForAsr = Defaults[.use_midpoint_method_for_asr]
            
            var url = URLComponents(string: "\(Info.practicesEndpoint)/prayer-times/")!
            
            url.queryItems = [
                URLQueryItem(name: "q", value: "\(encodedLocation.lowercased())"), // location
                URLQueryItem(name: "client", value: "ios") // client
            ]

            if useMidpointMethodForAsr {
                url.queryItems?.append(URLQueryItem(name: "asr_adjustment", value: "true")) // asr adjustment, if requested
            }
            
            URLSession.shared.dataTask(with: url.url!) { data, _, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                if let error = error {
                    print("Error fetching prayer times:", error)
                    return
                }
                guard let data = data else {
                    print("No data received")
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(Types.PrayerTimes.PrayerTimesResponse.self, from: data)
                    DispatchQueue.main.async {
                        Defaults[.prayer_times] = decoded
                    }
                } catch {
                    print("Decoding error:", error)
                }
            }.resume()
        }
        
        func refresh() {
            guard let data = Defaults[.prayer_times] else { return }
            let location = "\(data.city),\(data.region),\(data.country)"
            Defaults[.prayer_times_location] = location
            fetchPrayerTimes(for: location)
        }
        
        func removeSavedCity() {
            Defaults[.prayer_times_location] = nil
            Defaults[.prayer_times] = nil
            
            Task {
                try? await Utilities.Notifications.syncWithDatabase()
            }
        }
    }
}
