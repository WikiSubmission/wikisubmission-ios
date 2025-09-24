import Foundation
import SwiftUI

extension Utilities.PrayerTimes {
    class PrayerTimesManager: ObservableObject {
        static let shared = PrayerTimesManager()
        
        @Published var prayerTimesData: Types.PrayerTimes.PrayerTimesResponse? {
            didSet {
                if let data = prayerTimesData {
                    if let encoded = try? JSONEncoder().encode(data) {
                        UserDefaults.standard.set(encoded, forKey: "prayerTimesData")
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: "prayerTimesData")
                }
            }
        }
        @Published var isLoading = false
        
        @ObservedObject var networkMonitor = Utilities.System.NetworkMonitor.shared
        
        private var refreshTimer: Timer?
        
        init() {
            if let data = UserDefaults.standard.data(forKey: "prayerTimesData") {
                prayerTimesData = try? JSONDecoder().decode(Types.PrayerTimes.PrayerTimesResponse.self, from: data)
            }
            startTimer()
        }
        
        deinit {
            refreshTimer?.invalidate()
        }
        
        func fetchPrayerTimes(for location: String) {
            
            guard networkMonitor.hasInternet else { return }
            
            isLoading = true
            let encodedCity = location.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? location
            let urlString = "https://practices.wikisubmission.org/prayer-times/\(encodedCity.lowercased())?client=ios"
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
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
                        self.prayerTimesData = decoded
                    }
                } catch {
                    print("Decoding error:", error)
                }
            }.resume()
        }
        
        func refresh() {
            guard let data = prayerTimesData else { return }
            let location = "\(data.city),\(data.region),\(data.country)"
            fetchPrayerTimes(for: location)
        }
        
        private func startTimer() {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.refresh()
            }
        }
        
        func removeSavedCity() {
            prayerTimesData = nil
        }
    }
}
