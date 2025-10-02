// SPDX-License-Identifier: GPL-2.0-or-later
// See LICENSE file for full license text.

import SwiftUI

@main
struct SubmissionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var alertManager = Utilities.System.GlobalAlertManager.shared

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
