import SwiftUI
import Defaults
import SwiftData

extension Defaults.Keys {
    static let inAppNotices_lastCheckedForUpdates = Key<Date>("inAppNotices_lastCheckedForUpdates", default: .distantPast)
}

// MARK: - Inline Notice (for Home title section)

struct InAppNoticesBanner: View {
    @ObservedObject private var appUpdateManager = AppUpdateManager.shared
    @ObservedObject private var quranDataManager = QuranDataManager.shared
    @Default(.inAppNotices_lastCheckedForUpdates) private var lastCheckedForUpdates

    @State private var showSheet = false

    private var hasAppUpdate: Bool { appUpdateManager.updateAvailable }
    private var hasDataUpdate: Bool { quranDataManager.updatesAvailable }
    private var hasUpdate: Bool { hasAppUpdate || hasDataUpdate }

    /// Minimum interval between update checks (12 minutes)
    private static let minimumCheckInterval: TimeInterval = 12 * 60

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            if hasAppUpdate {
                Button {
                    showSheet = true
                } label: {
                    Text("APP UPDATE AVAILABLE →")
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.red)
                }
                .pushToLeft()
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .zIndex(2)
            }

            if hasDataUpdate {
                Button {
                    showSheet = true
                } label: {
                    Text("DATA UPDATE AVAILABLE →")
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.accent)
                }
                .pushToLeft()
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .zIndex(2)
            }
        }
        .onAppear {
            checkForUpdatesIfNeeded()
        }
        .sheet(isPresented: $showSheet) {
            InAppNoticesSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func checkForUpdatesIfNeeded() {
        guard !hasUpdate,
              Date().timeIntervalSince(lastCheckedForUpdates) > Self.minimumCheckInterval else { return }

        Task {
            await appUpdateManager.checkForUpdates()
            await quranDataManager.checkForUpdates()
            lastCheckedForUpdates = Date()
        }
    }
}

// MARK: - Notices Sheet

struct InAppNoticesSheet: View {
    @ObservedObject private var appUpdateManager = AppUpdateManager.shared
    @ObservedObject private var quranDataManager = QuranDataManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Notices")
                        .font(DS.Typography.heroMD)
                    Text("The following updates are available:")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)
                }

                if appUpdateManager.updateAvailable {
                    AppUpdateNotice()
                }

                if quranDataManager.updatesAvailable {
                    QuranDataUpdateNotice()
                }
            }
            .padding()
        }
    }
}

// MARK: - App Update Notice

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

// MARK: - Quran Data Update Notice

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
                .font(DS.Typography.eyebrow)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .pushToLeft()
        }
    }
}
