import SwiftUI
import SheetKit
import Defaults

struct HomeView: View {
    
    @State private var shouldScrollToTop = false
    
    @Default(.active_tab) private var activeTab
    @Default(.daily_verse) private var dailyVerse
    @Default(.last_read_verse) private var lastReadVerse
    @Default(.primary_language) private var primaryLanguage
    @Default(.qibla_enabled) private var qibla

    @Environment(\.colorScheme) private var theme
    
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
                    
                    if ZikrAudioManager.shared.isPlaying {
                        Button {
                            activeTab = .zikr
                        } label: {
                            HStack {
                                AnimatedWaveform()
                                Text("\(ZikrAudioManager.shared.currentTrack?.capitalized.split(separator: ".")[0] ?? "")")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .buttonStyle(SignatureButtonStyle())
                    }
                    
                    VStack(spacing: 24) {
                        Group {
                            VStack(spacing: 16) {
                                FlexStack(verticalSpacing: 12, horizontalSpacing: 16) {
                                    TinyCard(title: "Random", systemImage: "bubbles.and.sparkles") {
                                        QuranRandomVerse()
                                    }
                                    TinyCard(title: "Bookmarks", systemImage: "bookmark") {
                                        QuranBookmarks()
                                    }
                                    TinyCard(title: "Introduction", systemImage: "apple.image.playground") {
                                        WebView(url: URL(string: "https://library.wikisubmission.org/file/quran-the-final-testament-introduction")!)
                                            .navigationTitle("Introduction")
                                    }
                                    TinyCard(title: "Appendices", systemImage: "info.square") {
                                        WebView(url: URL(string: "https://wikisubmission.org/appendices")!)
                                            .navigationTitle("Appendices")
                                    }
                                    TinyCardWithAction(title: "Prayer Times", systemImage: "bolt.heart") {
                                        activeTab = .prayer
                                    }
                                    if qibla {
                                        TinyCard(title: "Qibla", systemImage: "safari") {
                                            QiblaView()
                                        }
                                    }
                                    if !qibla {
                                        TinyCardWithAction(title: "Zikr", systemImage: "music.note") {
                                            activeTab = .zikr
                                        }
                                    }
                                    TinyCard(title: "Notifications", systemImage: "bell.square") {
                                        NotificationsView()
                                    }
                                    TinyCard(title: "\(lastReadVerse)", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                                        NavigationStack {
                                            QuranReaderView(chapter: Int(lastReadVerse.split(separator: ":")[0]) ?? 1, scrollToVerseID: lastReadVerse)
                                        }
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
