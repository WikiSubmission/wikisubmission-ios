import Foundation
import SwiftUI
import Combine

final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    let AudioPlayerManager = Utilities.Quran.QuranAudioManager.shared
    let PrayerTimesManager = Utilities.PrayerTimes.PrayerTimesManager.shared
    let NetworkMonitor = Utilities.System.NetworkMonitor.shared
    let GlobalAlertManager = Utilities.System.GlobalAlertManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupChangeForwarding()
    }
    
    private func setupChangeForwarding() {
        // Forward all manager changes to trigger UI updates
        let publishers = [
            AudioPlayerManager.objectWillChange.eraseToAnyPublisher(),
            PrayerTimesManager.objectWillChange.eraseToAnyPublisher(),
            NetworkMonitor.objectWillChange.eraseToAnyPublisher(),
            GlobalAlertManager.objectWillChange.eraseToAnyPublisher(),
        ]
        
        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
