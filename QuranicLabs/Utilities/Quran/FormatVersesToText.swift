import AlertKit
import Defaults
extension Utilities {
    @MainActor
    static func formatVersesToText(_ verses: [Types.Quran.Data], showAlert: Bool = true) -> String {
        var baseText = ""
        
        for verse in verses {
            if Defaults[.subtitles], verse.verse_subtitle_english != nil {
                baseText += "\(verse.getSubtitle(for: Defaults[.primary_language]) ?? "")\n\n"
            }
            
            baseText += "[\(verse.verse_id)] \(verse.getPrimaryText(for: Defaults[.primary_language]))\n\n"
            
            if Defaults[.secondary_language] != .none {
                baseText += "[\(verse.verse_id)] \(verse.getSecondaryText(for: Defaults[.secondary_language]) ?? "")\n\n"
            }
            
            if Defaults[.arabic] {
                baseText += "\(verse.verse_text_arabic)\n\n"
            }
            
            if Defaults[.transliteration] {
                baseText += "\(verse.verse_text_transliterated)\n\n"
            }
            
            if Defaults[.footnotes], verse.verse_footnote_english != nil {
                baseText += "\(verse.getFootnote(for: Defaults[.primary_language]) ?? "")\n\n"
            }
        }
        
        if showAlert {
            AlertKitAPI.present(
                title: "Verse(s) Copied",
                icon: .done,
                style: .iOS17AppleMusic,
                haptic: .success
            )
        }
        
        return baseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
