import SwiftUI
import SwiftData
import Combine
import Defaults

class Router: ObservableObject {
    static let shared = Router()
    
    @Published var homePath = NavigationPath()
    @Published var quranPath = NavigationPath()
    @Published var prayerPath = NavigationPath()
    @Published var musicPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    @Published var openQuranSearchBar = false
    @Published var musicScrollToTrackId: UUID?

    // Model context for views that need it
    var modelContext: ModelContext?
    
    private init() {}
        
    func pathBinding(for tab: TabItem) -> Binding<NavigationPath> {
        switch tab {
        case .home: return Binding(get: { self.homePath }, set: { self.homePath = $0 })
        case .quran: return Binding(get: { self.quranPath }, set: { self.quranPath = $0 })
        case .prayer: return Binding(get: { self.prayerPath }, set: { self.prayerPath = $0 })
        case .music: return Binding(get: { self.musicPath }, set: { self.musicPath = $0 })
        case .settings: return Binding(get: { self.settingsPath }, set: { self.settingsPath = $0 })
        }
    }
    
    private func pushToPath(destination: Destination, tab: TabItem) {
        switch tab {
        case .home: homePath.append(destination)
        case .quran: quranPath.append(destination)
        case .prayer: prayerPath.append(destination)
        case .music: musicPath.append(destination)
        case .settings: settingsPath.append(destination)
        }
    }
        
    func push(_ destination: Destination) {
        let currentTab = Defaults[.active_tab]
        if destination.tab != currentTab {
            navigate(to: destination)
        } else {
            pushToPath(destination: destination, tab: currentTab)
        }
    }

    /// Appends a destination to the current tab's navigation path without changing tabs
    /// or performing any rerouting logic.
    func append(_ destination: Destination) {
        let currentTab = Defaults[.active_tab]
        if destination.tab != currentTab {
            selectTab(destination.tab)
            pushToPath(destination: destination, tab: destination.tab)
        } else {
            pushToPath(destination: destination, tab: currentTab)
        }
    }
    
    func navigate(to destination: Destination) {
        // Handle .track specially - just scroll to it in the Music view
        if case .track(let id) = destination {
            selectTab(.music)
            musicScrollToTrackId = id
            return
        }

        let targetTab = destination.tab

        // If destination is a tab root, just select the tab without pushing
        if destination.isTabRoot {
            selectTab(targetTab)
            return
        }

        let currentTab = Defaults[.active_tab]

        if targetTab != currentTab {
            Defaults[.active_tab] = targetTab

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.pushToPath(destination: destination, tab: targetTab)
            }
        } else {
            self.pushToPath(destination: destination, tab: targetTab)
        }
    }
    
    func pop(from tab: TabItem) {
        switch tab {
        case .home: if !homePath.isEmpty { homePath.removeLast() }
        case .quran: if !quranPath.isEmpty { quranPath.removeLast() }
        case .prayer: if !prayerPath.isEmpty { prayerPath.removeLast() }
        case .music: if !musicPath.isEmpty { musicPath.removeLast() }
        case .settings: if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }
    
    func popToRoot(for tab: TabItem) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .quran: quranPath = NavigationPath()
        case .prayer: prayerPath = NavigationPath()
        case .music: musicPath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        }
    }
    
    func resetAllPaths() {
        homePath = NavigationPath()
        quranPath = NavigationPath()
        prayerPath = NavigationPath()
        musicPath = NavigationPath()
        settingsPath = NavigationPath()
    }
    
    func navigate(to url: URL) {
        guard let destination = Destination.from(url: url) else { return }
        navigate(to: destination)
    }
    
    func selectTab(_ tab: TabItem) {
        if Defaults[.active_tab] != tab {
            Defaults[.active_tab] = tab
        }
    }
        
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        destination.view
    }
}

extension Router {
    enum Destination: Hashable {
        // Home
        case home
        
        // Quran
        case quran
        case ai
        case randomVerse
        case readingHistory
        case insights
        case chapter(chapterNumber: Int, scrollToVerseNumber: Int? = nil)
        case verseInfo(chapterNumber: Int, verseNumber: Int)
        case wordInfo(chapterNumber: Int, verseNumber: Int, wordIndex: Int)
        
        // Prayer
        case prayerTimes
        
        // Music
        case music
        case track(id: UUID)

        // Settings
        case settings
                
        var urlPath: String {
            switch self {
            case .home: return "home"
            case .quran: return "quran"
            case .ai: return "ai"
            case .randomVerse: return "quran/random-verse"
            case .readingHistory: return "quran/reading-history"
            case .insights: return "quran/insights"
            case .chapter(let chapterNumber, let verseNumber):
                if let verse = verseNumber {
                    return "quran/verse/\(chapterNumber):\(verse)"
                }
                return "quran/chapter/\(chapterNumber)"
            case .verseInfo(let chapterNumber, let verseNumber):
                return "quran/verse-info/\(chapterNumber)/\(verseNumber)"
            case .wordInfo(let chapterNumber, let verseNumber, let wordIndex):
                return "quran/word-info/\(chapterNumber)/\(verseNumber)/\(wordIndex)"
            case .prayerTimes: return "prayer-times"
            case .music: return "music"
            case .track(let id): return "music/track/\(id.uuidString)"
            case .settings: return "settings"
            }
        }
        
        var url: URL {
            URL(string: "wikisubmission://\(urlPath)")!
        }
        
        var tab: TabItem {
            switch self {
            case .home: return .home
            case .quran, .ai, .randomVerse, .readingHistory, .insights, .chapter, .verseInfo, .wordInfo: return .quran
            case .prayerTimes: return .prayer
            case .music, .track: return .music
            case .settings: return .settings
            }
        }

        var isTabRoot: Bool {
            switch self {
            case .home, .quran, .prayerTimes, .music, .settings: return true
            default: return false
            }
        }
        
        @ViewBuilder
        var view: some View {
            switch self {
            case .home:
                Home()
            case .quran:
                Quran()
            case .ai:
                AIChat()
            case .settings:
                Settings()
            case .randomVerse:
                Quran_Content_RandomVerse()
            case .readingHistory:
                Quran_Content_ReadingHistory()
            case .insights:
                Quran_Content_Insights()
            case .chapter(let chapterNumber, let scrollToVerseNumber):
                Quran_Content_ChapterReader(
                    chapterNumber: chapterNumber,
                    options: scrollToVerseNumber != nil ? .init(
                        scrollToVerseNumber: scrollToVerseNumber!
                    ) : .init()
                )
            case .verseInfo(let chapterNumber, let verseNumber):
                VerseInfoWrapper(chapterNumber: chapterNumber, verseNumber: verseNumber)
            case .wordInfo(let chapterNumber, let verseNumber, let wordIndex):
                WordInfoWrapper(chapterNumber: chapterNumber, verseNumber: verseNumber, wordIndex: wordIndex)
            case .prayerTimes:
                Prayer()
            case .music, .track:
                Music()
            }
        }
                
        static func from(url: URL) -> Destination? {
            guard url.scheme == "wikisubmission" else { return nil }

            // Combine host and path to get full route
            // e.g., wikisubmission://music/track/uuid -> host="music", path="/track/uuid"
            var fullPath = ""
            if let host = url.host {
                fullPath = host
            }
            let pathPart = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !pathPart.isEmpty {
                fullPath += "/\(pathPart)"
            }

            let components = fullPath.split(separator: "/").map(String.init)
            guard !components.isEmpty else { return nil }

            switch components[0] {
            case "settings":
                if components.count == 1 { return .settings }

            case "quran":
                if components.count == 1 { return .quran }

                switch components[1] {
                case "random-verse":
                    return .randomVerse

                case "reading-history":
                    return .readingHistory

                case "insights":
                    return .insights

                case "verse":
                    guard components.count >= 3 else { return nil }
                    let verseRef = components[2].split(separator: ":").map(String.init)
                    guard verseRef.count == 2,
                          let chapterNumber = Int(verseRef[0]),
                          let verseNumber = Int(verseRef[1]) else { return nil }
                    return .chapter(chapterNumber: chapterNumber, scrollToVerseNumber: verseNumber)

                case "verse-info":
                    guard components.count == 4,
                          let chapterNumber = Int(components[2]),
                          let verseNumber = Int(components[3]) else { return nil }
                    return .verseInfo(chapterNumber: chapterNumber, verseNumber: verseNumber)

                case "word-info":
                    guard components.count == 5,
                          let chapterNumber = Int(components[2]),
                          let verseNumber = Int(components[3]),
                          let wordIndex = Int(components[4]) else { return nil }
                    return .wordInfo(chapterNumber: chapterNumber, verseNumber: verseNumber, wordIndex: wordIndex)

                case "chapter":
                    guard components.count >= 3,
                          let chapterNumber = Int(components[2]) else { return nil }
                    return .chapter(chapterNumber: chapterNumber)

                default:
                    return nil
                }

            case "ai":
                return .ai

            case "prayer-times":
                return .prayerTimes

            case "music":
                if components.count >= 3 && components[1] == "track",
                   let trackId = UUID(uuidString: components[2]) {
                    return .track(id: trackId)
                }
                return .music

            default:
                return nil
            }

            return nil
        }
    }
}

extension Router.Destination: Identifiable {
    var id: String { urlPath }
}

// Wrapper view to provide context to VerseInfo
private struct VerseInfoWrapper: View {
    @Environment(\.modelContext) private var modelContext

    let chapterNumber: Int
    let verseNumber: Int

    var body: some View {
        if let unified = QuranUnified.fetchVerse(chapter: chapterNumber, verse: verseNumber, context: modelContext) {
            Quran_Content_VerseInfo(data: unified)
        } else {
            VStack {
                ProgressView()
                Text("Loading verse...")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Wrapper view to provide context to WordExpandedInfo
private struct WordInfoWrapper: View {
    @Environment(\.modelContext) private var modelContext

    let chapterNumber: Int
    let verseNumber: Int
    let wordIndex: Int

    var body: some View {
        if let unified = QuranUnified.fetchVerse(chapter: chapterNumber, verse: verseNumber, context: modelContext),
           let word = unified.wordByWord.first(where: { $0.word_index == wordIndex }) {
            Quran_Element_WordExpandedInfo(verse: unified, word: word)
        } else {
            VStack {
                ProgressView()
                Text("Loading word...")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
