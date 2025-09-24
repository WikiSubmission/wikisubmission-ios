import SwiftUI
import Defaults

struct PrimaryLanguagePicker: View {
    @Default(.primary_language) private var primaryLanguage

    var body: some View {
        BetterPicker(selection: $primaryLanguage, previewLabel: "Primary Language", previewIcon: "globe") { lang in
            HStack {
                Image(lang.countryCode)
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(lang.rawValue.capitalizeFirstLetter())
            }
        }
    }
}
