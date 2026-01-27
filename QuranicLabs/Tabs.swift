import SwiftUI
import Defaults

// [Tab selection and corresponding views]
struct Tabs: View {
    @Default(.active_tab) private var activeTab
    
    var body: some View {
        TabView(selection: $activeTab) {
            Home()
                .tag(TabItem.home)
                .tabItem {
                    Label(TabItem.home.rawValue, systemImage: TabItem.home.symbol)
                }
            
            Quran()
                .tag(TabItem.quran)
                .tabItem {
                    Label(TabItem.quran.rawValue, systemImage: TabItem.quran.symbol)
                }
            
            Prayer()
                .tag(TabItem.prayer)
                .tabItem {
                    Label(TabItem.prayer.rawValue, systemImage: TabItem.prayer.symbol)
                }
            
            Music()
                .tag(TabItem.music)
                .tabItem {
                    Label(TabItem.music.rawValue, systemImage: TabItem.music.symbol)
                }
            
            Settings()
                .tag(TabItem.settings)
                .tabItem {
                    Label(TabItem.settings.rawValue, systemImage: TabItem.settings.symbol)
                }
        }
    }
}

enum TabItem: String, CaseIterable, Equatable, Defaults.Serializable {
    case home = "Home"
    case quran = "Quran"
    case prayer = "Prayer"
    case music = "Music"
    case settings = "Settings"
    
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .quran: return "book.closed.fill"
        case .prayer: return "bolt.heart.fill"
        case .music: return "music.note"
        case .settings: return "gearshape.fill"
        }
    }
}
