import SwiftUI
import Defaults
import SwiftData

extension Defaults.Keys {
    static let inAppNotices_lastCheckedForUpdates = Key<Date>("inAppNotices_lastCheckedForUpdates", default: .distantPast)
}

struct InAppNotices: View {
    @ObservedObject private var appUpdateManager = AppUpdateManager.shared
    @ObservedObject private var quranDataManager = QuranDataManager.shared

    @Default(.inAppNotices_lastCheckedForUpdates) private var lastCheckedForUpdates
    @State private var isCheckingForUpdates = false
    @State private var lastManualCheck: Date = .distantPast

    private var hasUpdate: Bool {
        appUpdateManager.updateAvailable || quranDataManager.updatesAvailable
    }

    private var recentlyCheckedManually: Bool {
        Date().timeIntervalSince(lastManualCheck) < 15
    }

    /// Minimum interval between update checks triggered by onAppear (12 minutes)
    private static let minimumCheckInterval: TimeInterval = 12 * 60

    var body: some View {
        VStack {
            NavigationLink {
                VStack {
                    if isCheckingForUpdates {
                        ProgressView()
                    } else {
                        ScrollView {
                            if hasUpdate {
                                AppUpdateNotice()
                                QuranDataUpdateNotice()
                            } else if recentlyCheckedManually {
                                Card(title: "No New Updates", options: .init(
                                    systemImage: "checkmark.circle.fill",
                                    style: .secondary
                                ))
                            } else {
                                Card(title: "All Caught Up", options: .action(
                                    subtitle: "Tap to check for any updates",
                                    systemImage: "checkmark.circle.fill",
                                    imageAlignment: .top
                                ) {
                                    Task {
                                        await checkForUpdates(manual: true)
                                    }
                                })
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("Notices")
                .onAppear {
                    checkForUpdatesIfNeeded(threshold: 5)
                }
            } label: {
                Image(systemName: hasUpdate ? "bell.badge" : "bell")
                    .foregroundStyle(hasUpdate ? .red : .accent)
            }
        }
        .onAppear {
            checkForUpdatesIfNeeded(threshold: Self.minimumCheckInterval)
        }
    }

    private func checkForUpdatesIfNeeded(threshold: TimeInterval) {
        guard !hasUpdate,
              !isCheckingForUpdates,
              Date().timeIntervalSince(lastCheckedForUpdates) > threshold else { return }

        Task {
            await checkForUpdates()
        }
    }

    private func checkForUpdates(manual: Bool = false) async {
        isCheckingForUpdates = true

        await appUpdateManager.checkForUpdates()
        await quranDataManager.checkForUpdates()

        withAnimation {
            lastCheckedForUpdates = Date()
            if manual {
                lastManualCheck = Date()
            }
        }
        isCheckingForUpdates = false
    }
}

struct AppUpdateNotice: View {
    @StateObject var appUpdateManager = AppUpdateManager.shared

    var body: some View {
        if appUpdateManager.updateAvailable {
            Card(title: "App update available", options: .action(
                subtitle: "Version \(appUpdateManager.latestVersion ?? "") is now available. Tap to update.",
                systemImage: "arrow.down.app.fill",
                imageAlignment: .top,
                style: .accent
            ) {
                appUpdateManager.openAppStore()
            })
            .removeParentListStyle()
        }
    }
}

struct QuranDataUpdateNotice: View {
    @Environment(\.modelContext) var modelContext
    @StateObject var quranDataManager = QuranDataManager.shared
    @State private var presentConfirmationDialog = false
    @State private var filesToUpdateText = ""
    
    var body: some View {
        if quranDataManager.updatesAvailable {
            Card(title: "Data update available", options: .action(
                subtitle: "Updates include text improvements and corrections. Tap to download now.",
                systemImage: "square.and.arrow.down.fill",
                imageAlignment: .top,
                style: .accent
            ) {
                presentConfirmationDialog = true
            })
            .onAppear {
                filesToUpdateText = "**\(quranDataManager.pendingUpdates.count) files to update:** \(Array(Set(quranDataManager.pendingUpdates.map { $0.displayName })).joined(separator: ", "))"
            }
            .removeParentListStyle()
            .confirmationDialog("Are you sure? This process may take a moment to complete.", isPresented: $presentConfirmationDialog, titleVisibility: .visible) {
                Group {
                    Button("Confirm" ) {
                        Task {
                            await quranDataManager.downloadUpdates(modelContext: modelContext)
                        }
                    }
                }
            }
            
            Text(.init(filesToUpdateText))
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .pushToLeft()
        }
    }
}
