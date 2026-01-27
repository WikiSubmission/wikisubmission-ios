import SwiftUI
import Defaults

struct QuranSettings_LanguagePicker: View {
    @Default(.quran_primary_language) private var primaryLanguage
    @Default(.quran_secondary_language) private var secondaryLanguage

    enum LanguageType {
        case primary, secondary
    }

    var type: LanguageType
    var body: some View {
        if type == .primary {
            BetterPicker(selection: $primaryLanguage, previewLabel: "Primary Language", previewIcon: "globe") { lang in
                HStack {
                    Image(lang.countryCode)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(lang.rawValue.capitalizeFirstLetter())
                }
            }
        } else {
            BetterPicker(
                selection: $secondaryLanguage,
                previewLabel: "Secondary Language",
                previewIcon: "globe",
                allowedValues: QuranSelectableSecondaryLanguage.allCases.filter { $0.rawValue != primaryLanguage.rawValue }
            ) { lang in
                HStack {
                    if let code = lang.countryCode {
                        Image(code)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    Text(lang.displayText)
                }
            }
        }
    }
}
