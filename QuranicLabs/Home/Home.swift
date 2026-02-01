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
    // [Global app router]
    @ObservedObject var router = Router.shared
    
    // [Theme]
    @Environment(\.colorScheme) private var theme

    var body: some View {
        NavigationStack(path: router.pathBinding(for: .home)) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 48) {
                    Group {
                        titleSection
                    }
                    .padding(.horizontal)

                    Group {
                        Home_QuranSection()
                    }
                    .padding()
                    .background(
                        Color.secondary.opacity(theme == .dark ? 0.10 : 0.06)
                            .padding(.top, -500)
                    )

                    Group {
                        Home_PrayerSection()
                    }
                        .padding()
                    
                    Group {
                        Home_MusicSection()
                    }
                        .padding()
                    
                    VStack(spacing: 48) {
                        Group {
                            Home_SupportWikiSubmissionSection()
                            Home_FooterSection()
                        }
                        .padding()
                    }
                    .background(
                        Color.accent.opacity(theme == .dark ? 0.10 : 0.06)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
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
        Group {
            VStack(spacing: 4) {
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
        }
        .removeParentListStyle()
    }
}
