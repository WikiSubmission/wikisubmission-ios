import SwiftUI
import SheetKit

struct TabsView: View {
    @State private var activeTab: TabItem = .home

    var body: some View {
        TabView(selection: $activeTab) {
            HomeView()
                .tabItem {
                    Label(TabItem.home.rawValue, systemImage: TabItem.home.symbol)
                }
                .tag(TabItem.home)

            PrayerTimesView()
            .tabItem {
                Label(TabItem.prayer.rawValue, systemImage: TabItem.prayer.symbol)
            }
            .tag(TabItem.prayer)
            
            ResourcesView()
            .tabItem {
                Label(TabItem.resources.rawValue, systemImage: TabItem.resources.symbol)
            }
            .tag(TabItem.resources)

            SettingsView()
                .tabItem {
                    Label(TabItem.settings.rawValue, systemImage: TabItem.settings.symbol)
                }
                .tag(TabItem.settings)
        }
        .onOpenURL { url in
            guard url.scheme == "wikisubmission" else { return }

            if url.host == "prayer-times" {
                activeTab = .prayer
            } else if url.host == "verse" {
                let verseId = url.lastPathComponent
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(
                            chapter: Int(verseId.split(separator: ":")[0]) ?? 1,
                            scrollToVerseID: verseId
                        )
                    }
                }
            } else if url.host == "chapter" {
                let chapterNumber = Int(url.lastPathComponent)
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(
                            chapter: chapterNumber ?? 1
                        )
                    }
                }
            }
        }
    }
}

enum TabItem: String, CaseIterable, Equatable {
    case home = "Home"
    case prayer = "Prayer"
    case resources = "Resources"
    case settings = "Settings"
    
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .prayer: return "bolt.heart.fill"
        case .resources: return "info.circle.text.page.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    TabsView()
}
