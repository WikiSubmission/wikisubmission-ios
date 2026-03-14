import SwiftUI

#Preview {
    Main()
        .modelContainer(for: [
            QuranChaptersSD.self,
            QuranFootnotesSD.self,
            QuranIndexSD.self,
            QuranSubtitlesSD.self,
            QuranTextSD.self,
            QuranWordByWordSD.self
        ])
}

struct Home: View {
    @ObservedObject var router = Router.shared
    @Environment(\.colorScheme) private var theme

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .home)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.section) {
                    titleSection
                        .padding(.horizontal)

                    Home_QuranSection()
                        .padding()
                        .background(
                            Color.secondary.opacity(theme == .dark ? 0.10 : 0.06)
                                .padding(.top, -500)
                        )

                    Home_PrayerSection()
                        .padding()

                    Home_MusicSection()
                        .padding()

                    VStack(spacing: DS.Spacing.section) {
                        Home_SupportWikiSubmissionSection()
                        Home_FooterSection()
                    }
                    .padding()
                    .background(
                        Color.accent.opacity(theme == .dark ? 0.10 : 0.06)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.pill))
                            .padding(.bottom, -500)
                    )
                }
            }
            .toolbar {
                InAppNotices()
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image("wikisubmission")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .pushToLeft()
            Text("Peace be upon you")
                .font(.largeTitle)
                .fontDesign(.serif)
                .pushToLeft()
        }
        .removeParentListStyle()
    }
}
