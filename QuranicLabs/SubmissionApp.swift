// SPDX-License-Identifier: GPL-2.0-or-later
// See LICENSE file for full license text.

import SwiftUI
import Defaults
import SheetKit

@main
struct SubmissionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var alertManager = Utilities.System.GlobalAlertManager.shared

    @Default(.active_tab) var activeTab
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(AppEnvironment.shared)
                .task {
                    await Utilities.System.startupTasks()
                }
                .sheet(item: $alertManager.alert) { alert in
                    GlobalAlertView(alert: alert)
                        .presentationDetents([.medium])
                }
                .onOpenURL { url in
                    guard url.scheme == "wikisubmission" else { return }
                    
                    if url.host == "prayer-times" {
                        activeTab = .prayer
                    } else if url.host == "verse" {
                        activeTab = .home
                        let verseId = url.lastPathComponent
                        let chapter = Int(verseId.split(separator: ":")[0]) ?? 1
                        SheetKit().presentWithEnvironment {
                            NavigationStack {
                                QuranReaderView(
                                    chapter: chapter,
                                    scrollToVerseID: verseId
                                )
                            }
                        }
                    } else if url.host == "chapter" {
                        activeTab = .home
                        let chapterNumber = Int(url.lastPathComponent) ?? 1
                        SheetKit().presentWithEnvironment {
                            NavigationStack {
                                QuranReaderView(
                                    chapter: chapterNumber
                                )
                            }
                        }
                    }
                }
        }
    }
}
