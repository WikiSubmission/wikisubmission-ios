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
        }
    }
}
