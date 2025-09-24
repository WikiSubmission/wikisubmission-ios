import SwiftUI
import Defaults

struct SecondaryLanguagePicker: View {
    @Default(.primary_language) private var primaryLanguage
    @Default(.secondary_language) private var secondaryLanguage

    var body: some View {
        BetterPicker(
            selection: $secondaryLanguage,
            previewLabel: "Secondary Language",
            previewIcon: "globe",
            allowedValues: Types.Quran.SecondaryLanguage.allCases.filter { $0.rawValue != primaryLanguage.rawValue }
        ) { lang in
            HStack {
                if let code = lang.countryCode {
                    Image(code)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(lang.rawValue.capitalizeFirstLetter())
            }
        }
    }
}
