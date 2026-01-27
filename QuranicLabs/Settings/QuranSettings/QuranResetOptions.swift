import SwiftUI
import Defaults

struct QuranSettings_ResetOptions: View {
    @State private var presentResetQuranSettingsDialog = false
    @State private var presentResetQuranDataDialog = false
    
    @StateObject var quranDataManager = QuranDataManager.shared
    
    @Environment(\.modelContext) var modelContext

    var body: some View {
        Section {
            NavigationLink {
                List {
                    Button(role: .destructive) {
                        self.presentResetQuranSettingsDialog = true
                    } label: {
                        Label("Reset Quran Settings", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    }
                    .confirmationDialog("Are you sure you want to reset your Quran settings?", isPresented: $presentResetQuranSettingsDialog, titleVisibility: .visible) {
                        Group {
                            Button("Confirm", role: .destructive) {
                                withAnimation {
                                    Defaults.resetQuranPreferences()
                                }
                            }
                        }
                    }
                    
                    Button(role: .destructive) {
                        self.presentResetQuranDataDialog = true
                    } label: {
                        Label("Redownload Quran Data", systemImage: "square.and.arrow.down")
                    }
                    .confirmationDialog("Are you sure? This process may take a moment to complete.", isPresented: $presentResetQuranDataDialog, titleVisibility: .visible) {
                        Group {
                            Button("Confirm", role: .destructive) {
                                Task {
                                    await quranDataManager.clearCDNCacheAndReloadFromBundle(modelContext: modelContext)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Reset Options")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Reset Options", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
    }
}
