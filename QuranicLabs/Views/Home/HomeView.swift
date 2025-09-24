import SwiftUI
import SheetKit
import Clerk

struct HomeView: View {
    @Environment(\.clerk) var clerk

    @Environment(\.colorScheme) private var theme
    @State private var authIsPresented = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    Text("Peace be upon you\(isSignedIn ? ", \(clerk.user!.firstName ?? "")" : "")")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .pushToLeft()
                }
                .padding()
                
                VStack(spacing: 24) {
                    Group {
                        VStack(spacing: 16) {
                            FlexStack(verticalSpacing: 8) {
                                TinyCard(title: "Search Quran", systemImage: "magnifyingglass.circle.fill") {
                                    QuranView(autoFocus: true)
                                }
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
                                TinyCard(title: "Prayer Times", systemImage: "bolt.heart.fill") {
                                    PrayerTimesView()
                                }
                                TinyCard(title: "Qibla", systemImage: "safari.fill") {
                                    QiblaView()
                                }
                            }
                        }
                        .padding()
                    }
                                        
                    VStack(spacing: 4) {
                        Text("BROWSE CHAPTERS")
                            .font(.footnote)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                            .pushToLeft()
                            .padding(.top)
                            .padding(.horizontal)
                        QuranView(hideSearchbar: true)
                    }
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    Color.clear.frame(height: 16)
                }
            }
        }
    }
    
    var isSignedIn: Bool {
        clerk.user != nil
    }
}

#Preview {
    MainView()
        .environmentObject(AppEnvironment.shared)
}
