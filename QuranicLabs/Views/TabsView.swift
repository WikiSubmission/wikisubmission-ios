import SwiftUI
import Defaults
import SheetKit

struct TabsView: View {
    @Default(.active_tab) private var activeTab

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
            
            ZikrView()
                .tabItem {
                    Label(TabItem.zikr.rawValue, systemImage: TabItem.zikr.symbol)
                }
                .tag(TabItem.zikr)

            SettingsView()
                .tabItem {
                    Label(TabItem.settings.rawValue, systemImage: TabItem.settings.symbol)
                }
                .tag(TabItem.settings)
        }
    }
}

enum TabItem: String, CaseIterable, Equatable, Defaults.Serializable {
    case home = "Home"
    case prayer = "Prayer"
    case resources = "Resources"
    case zikr = "Zikr"
    case settings = "Settings"
    
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .prayer: return "bolt.heart.fill"
        case .resources: return "info.circle.text.page.fill"
        case .zikr: return "music.note"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    TabsView()
}
