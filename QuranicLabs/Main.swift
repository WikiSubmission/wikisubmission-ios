import SwiftUI
import Defaults
import SwiftData
import Combine

struct Main: View {
    @StateObject private var router = Router.shared
    @StateObject private var quranDataManager = QuranDataManager.shared

    @Environment(\.modelContext) private var modelContext

    @Default(.onboarded) private var onboarded

    var body: some View {
        ZStack {
            // [Data initialization / update screen]
            if !quranDataManager.isReady {
                DataLoading(
                    statusText: quranDataManager.progress.displayText,
                    title: quranDataManager.progress.title
                )
                // [Onboarding page / only on first launch]
            } else if !onboarded {
                Onboarding()
            } else {
                // [Actual content]
                ZStack {
                    Tabs()
                    NowPlayingBar()
                }
            }
        }
        .task {
            await quranDataManager.initializeFromBundle(modelContext: modelContext)
            await Migrations.runAll()
            NotificationManager.registerForPushNotificationsIfNeeded()
        }
        .onOpenURL { url in
            router.navigate(to: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkTriggered)) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            router.navigate(to: url)
        }
    }
}

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
