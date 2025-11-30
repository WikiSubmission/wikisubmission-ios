import Foundation
import Combine
import SheetKit
import Defaults
import SwiftUI

extension Utilities.System {
    class DeepLinkManager: ObservableObject {
        static let shared = DeepLinkManager()
        
        enum Action: Equatable {
            case openVerse(chapter: Int, verseId: String)
            case openChapter(chapter: Int)
            case openPrayerTimes
            case none
        }

        @Published var action: Action = .none

        func trigger(_ newAction: Action) {
            // If the action is the same as the current one, reset then set to allow repeated triggers
            if action == newAction {
                action = .none
                // Small delay to ensure state change is registered
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.executeAction(newAction)
                }
            } else {
                executeAction(newAction)
            }
        }
        
        private func executeAction(_ newAction: Action) {
            action = newAction
            
            switch action {
            case .openChapter(let chapter):
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(chapter: chapter)
                    }
                }
                
            case .openVerse(let chapter, let verseId):
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(chapter: chapter, scrollToVerseID: verseId)
                    }
                }
                
            case .openPrayerTimes:
                Defaults[.active_tab] = .prayer
                
            case .none:
                break
            }
        }

        func reset() {
            action = .none
        }
    }
}
