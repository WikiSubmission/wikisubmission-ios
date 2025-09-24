import SwiftUI
import SheetKit
import Defaults

struct QuranMenu: View {
    var data: [Types.Quran.Data] = []
    
     @Default(.arabic) private var arabic
     @Default(.subtitles) private var subtitles
     @Default(.footnotes) private var footnotes
     @Default(.transliteration) private var transliteration
     @Default(.arabic_on_side) private var arabicOnSide
     @Default(.primary_language) private var primaryLanguage
     @Default(.secondary_language) private var secondaryLanguage
    
    var hideShareButton = false
    var body: some View {
        Menu {
            // Copy / Share actions
            if !hideShareButton && !data.isEmpty {
                Button {
                    SheetKit().presentWithEnvironment {
                        QuranShareVerses(data: data)
                    }
                } label: {
                    Label("Share/Copy...", systemImage: "square.and.arrow.up.fill")
                }
            }
            
            Divider()
            
            // Language
            Section("LANGUAGE") {
                PrimaryLanguagePicker()
                SecondaryLanguagePicker()
            }
            
            // Reader Settings
            Section("READER") {
                ArabicToggle()
                SubtitlesToggle()
                FootnotesToggle()
                TransliterationToggle()
            }
            
            // Language
            FontSizeSelector()
        } label: {
            Label("Settings", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
}

#Preview {
    QuranMenu()
}
