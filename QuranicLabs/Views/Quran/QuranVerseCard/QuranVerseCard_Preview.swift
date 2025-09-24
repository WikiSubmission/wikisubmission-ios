import SwiftUI

struct QuranVerseCard_Preview: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                QuranVerseCard(id: "2:20")
                VStack {
                    PrimaryLanguagePicker()
                    SecondaryLanguagePicker()
                    Divider()
                    FontSizeSelector()
                    Divider()
                    ArabicToggle()
                    ArabicPositionToggle()
                    SubtitlesToggle()
                    FootnotesToggle()
                    TransliterationToggle()
                    Divider()
                }
                .padding()
            }
        }
    }
}

#Preview {
    QuranVerseCard_Preview()
        .environmentObject(AppEnvironment.shared)
}
