import Foundation
import SwiftUI
import Clerk
import Combine

final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    let BookmarkManager = Utilities.Quran.BookmarkManager.shared
    let AudioPlayerManager = Utilities.Quran.QuranAudioManager.shared
    let PrayerTimesManager = Utilities.PrayerTimes.PrayerTimesManager.shared
    let NetworkMonitor = Utilities.System.NetworkMonitor.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupChangeForwarding()
    }
    
    private func setupChangeForwarding() {
        // Forward all manager changes to trigger UI updates
        let publishers = [
            BookmarkManager.objectWillChange.eraseToAnyPublisher(),
            AudioPlayerManager.objectWillChange.eraseToAnyPublisher(),
            PrayerTimesManager.objectWillChange.eraseToAnyPublisher(),
            NetworkMonitor.objectWillChange.eraseToAnyPublisher(),
        ]
        
        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
