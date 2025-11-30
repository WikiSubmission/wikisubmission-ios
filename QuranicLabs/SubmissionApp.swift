// SPDX-License-Identifier: GPL-2.0-or-later
// See LICENSE file for full license text.

import SwiftUI
import Defaults
import SheetKit

@main
struct SubmissionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var alertManager = Utilities.System.GlobalAlertManager.shared
    @StateObject private var deepLinkManager = Utilities.System.DeepLinkManager.shared

    @Default(.active_tab) var activeTab
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(AppEnvironment.shared)
                .environmentObject(deepLinkManager)
                .task {
                    await Utilities.System.startupTasks()
                }
                .sheet(item: $alertManager.alert) { alert in
                    GlobalAlertView(alert: alert)
                        .presentationDetents([.medium])
                }
                .onReceive(NotificationCenter.default.publisher(for: .deepLinkTriggered)) { notification in
                    guard let url = notification.userInfo?["url"] as? URL else {
                        return
                    }
                    handleDeepLink(url: url)
                }
        }
    }
    
    private func handleDeepLink(url: URL) {
        // Case: prayer times
        if url.absoluteString == "wikisubmission://prayer-times" {
            deepLinkManager.trigger(.openPrayerTimes)
            return
        }
        
        // Case: verse
        if url.host == "verse" {
            let verseId = url.lastPathComponent
            let chapter = Int(verseId.split(separator: ":")[0]) ?? 1
            deepLinkManager.trigger(.openVerse(chapter: chapter, verseId: verseId))
        }
        
        // Case: chapter
        else if url.host == "chapter" {
            let chapterNumber = Int(url.lastPathComponent) ?? 1
            deepLinkManager.trigger(.openChapter(chapter: chapterNumber))
        }
    }
}
