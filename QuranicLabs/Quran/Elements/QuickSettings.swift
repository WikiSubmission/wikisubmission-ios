import SwiftUI
import SheetKit
import Defaults

struct Quran_Element_QuickSettings: View {    
     @Default(.arabic) private var arabic
     @Default(.subtitles) private var subtitles
     @Default(.footnotes) private var footnotes
     @Default(.transliteration) private var transliteration
    
    var hideShareButton = false
    var body: some View {
        Menu {
            // Language
            Section("LANGUAGE") {
                QuranSettings_LanguagePicker(type: .primary)
                QuranSettings_LanguagePicker(type: .secondary)
            }
            
            // Reader Settings
            Section("READER") {
                QuranSettings_ArabicToggle()
                QuranSettings_WordByWordToggle()
                QuranSettings_SubtitlesToggle()
                QuranSettings_FootnotesToggle()
                QuranSettings_TransliterationToggle()
            }
            
            QuranSettings_ReaderStyle()
            
            // Language
            QuranSettings_FontSizeSlider()
        } label: {
            Label("Settings", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
}
