// SPDX-License-Identifier: GPL-2.0-or-later
// See LICENSE file for full license text.

import SwiftUI
import Clerk

@main
struct SubmissionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var clerk = Clerk.shared
    @State private var clerkLoaded = false

    var body: some Scene {
        WindowGroup {
            if clerkLoaded {
                MainView()
                    .environment(\.clerk, clerk)
                    .environmentObject(AppEnvironment.shared)
                    .task {
                        await Utilities.System.startupTasks()
                        
                        Task { @MainActor in
                            for await event in clerk.authEventEmitter.events {
                                switch event {
                                case .signUpCompleted:
                                    print("User signed up")
                                    break
                                case .signInCompleted:
                                    print("User signed in")
                                    await Utilities.System.signInTasks()
                                case .signedOut:
                                    await Utilities.System.signOutTasks()
                                    print("User signed out")
                                }
                            }
                        }
                    }
            } else {
                ProgressView()
                    .task {
                        clerk.configure(publishableKey: "pk_test_bmV3LXZ1bHR1cmUtNTIuY2xlcmsuYWNjb3VudHMuZGV2JA")
                        try? await clerk.load()
                        clerkLoaded = true
                    }
            }
        }
    }
}
