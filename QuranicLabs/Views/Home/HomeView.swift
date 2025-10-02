import SwiftUI
import SheetKit
import Defaults

struct HomeView: View {
    @State private var shouldScrollToTop = false
    @Environment(\.colorScheme) private var theme
    @Default(.active_tab) private var activeTab

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Group {
                        Text("Peace be upon you")
                            .font(.largeTitle)
                            .fontDesign(.serif)
                            .pushToLeft()
                    }
                    .padding()
                    
                    VStack(spacing: 24) {
                        Group {
                            VStack(spacing: 16) {
                                FlexStack(verticalSpacing: 12, horizontalSpacing: 16) {
                                    TinyCard(title: "Random", systemImage: "bubbles.and.sparkles.fill") {
                                        QuranRandomVerse()
                                    }
                                    TinyCard(title: "Bookmarks", systemImage: "bookmark.fill") {
                                        QuranBookmarks()
                                    }
                                    TinyCard(title: "Introduction", systemImage: "apple.image.playground.fill") {
                                        WebView(url: URL(string: "https://library.wikisubmission.org/file/quran-the-final-testament-introduction")!)
                                            .navigationTitle("Introduction")
                                    }
                                    TinyCard(title: "Appendices", systemImage: "info.square.fill") {
                                        WebView(url: URL(string: "https://wikisubmission.org/appendices")!)
                                            .navigationTitle("Appendices")
                                    }
                                    TinyCardWithAction(title: "Prayer Times", systemImage: "bolt.heart.fill") {
                                        activeTab = .prayer
                                    }
                                    TinyCard(title: "Qibla", systemImage: "safari.fill") {
                                        QiblaView()
                                    }
                                    TinyCard(title: "Notifications", systemImage: "bell.square.fill") {
                                        NotificationsView()
                                    }
                                }
                            }
                            .padding()
                        }
                                            
                        VStack(spacing: 12) {
                            Text("QURAN: THE FINAL TESTAMENT")
                                .font(.footnote)
                                .fontWeight(.light)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .pushToLeft()
                                .id("top")
                            QuranView(shouldScrollToTop: $shouldScrollToTop)
                        }
                        .padding(.top)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .onChange(of: shouldScrollToTop) { _, should in
                            if should == true {
                                withAnimation {
                                    proxy.scrollTo("top")
                                }
                                shouldScrollToTop = false
                            }
                        }
                        
                        Color.clear.frame(height: 16)
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppEnvironment.shared)
}
