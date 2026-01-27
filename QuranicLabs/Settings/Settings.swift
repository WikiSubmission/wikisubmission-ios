import SwiftUI
import Defaults

struct Settings: View {
    @ObservedObject var router = Router.shared

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .settings)) {
            VStack {
                List {
                    quranSettings
                    
                    prayerSettings
                    
                    appSettings
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                InAppNotices()
            }
        }
    }
    
    @ViewBuilder
    private var quranSettings: some View {
        Section(header: Label("QURAN", systemImage: "book.closed")) {
            QuranSettings_LanguagePicker(type: .primary)
            QuranSettings_LanguagePicker(type: .secondary)
            QuranSettings_PreviewVerse()
        }
        
        Section {
            QuranSettings_FontSizeSlider()
        }

        Section {
            QuranSettings_ReaderStyle()
        }

        Section {
            QuranSettings_ArabicToggle()
            QuranSettings_WordByWordToggle()
            QuranSettings_SubtitlesToggle()
            QuranSettings_FootnotesToggle()
            QuranSettings_TransliterationToggle()
        }
        
        Section {
            QuranSettings_ReciterPicker()
        }
        
        Section {
            QuranSettings_ResetOptions()
        }
    }
    
    @ViewBuilder
    private var prayerSettings: some View {
        Section(
            header: Label("PRAYER", systemImage: "bolt.heart"),
            footer: Text("Midpoint method is an alternative calculation method for afternoon prayer time based on the exact midway point between noon and sunset.")
        ) {
            PrayerSettings_AfternoonMethodToggle()
        }
    }
    
    @ViewBuilder
    private var appSettings: some View {
        Section(
            header: Label("APP", systemImage: "app")
        ) {
            AppSettings_Notifications()
        }
        
        Section {
            AppSettings_Info()
        }
        
        Home_FooterSection()
            .removeParentListStyle()
    }
}

#Preview {
    Settings()
        .modelContainer(for: [
            QuranChaptersSD.self,
            QuranFootnotesSD.self,
            QuranIndexSD.self,
            QuranSubtitlesSD.self,
            QuranTextSD.self,
            QuranWordByWordSD.self
        ])
}
