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
                    
                    Group {
                        VStack(spacing: 8) {
                            Text("PRACTICES")
                                .font(.footnote)
                                .fontWeight(.light)
                                .foregroundStyle(.secondary)
                                .pushToLeft()
                            
                            LargeCard(
                                title: "Prayer Times",
                                subtitle: "Get live prayer times for your city",
                                systemImage: "clock.fill"
                            ) {
                                
                            }
                        }
                        .padding()
                    }
                    .background(Color.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    Group {
                        VStack(spacing: 8) {
                            Text("RESOURCES")
                                .font(.footnote)
                                .fontWeight(.light)
                                .foregroundStyle(.secondary)
                                .pushToLeft()
                            
                            LargeCard(
                                title: "Quran Talk Blog",
                                subtitle: "Reflections and unique insights from the Quran",
                                image: "qurantalk"
                            ) {
                                WebView(url: URL(string: "https://qurantalkblog.com")!)
                                    .navigationTitle("Quran Talk Blog")
                            }
                            
                            LargeCard(
                                title: "Submission Archives",
                                subtitle: "Useful videos and community archives",
                                image: "submissionarchives"
                            ) {
                                WebView(url: URL(string: "https://youtube.com/@SubmissionArchives")!)
                                    .navigationTitle("Submission Archives")
                            }
                            
                            LargeCard(
                                title: "Submission Server",
                                subtitle: "Access the worldwide Submitter community",
                                image: "19"
                            ) {
                                WebView(url: URL(string: "https://discord.gg/submissionserver")!)
                                    .navigationTitle("Submission Server")
                            }
                            
                            LargeCard(
                                title: "WikiSubmission",
                                subtitle: "Join the Discord and help expand the project!",
                                image: "wikisubmission"
                            ) {
                                WebView(url: URL(string: "\(Info.developerDiscordLink)")!)
                                    .navigationTitle("WikiSubmission Discord")
                            }
                            
                            HStack {
                                NavigationLink {
                                    WebView(url: URL(string: "https://wikisubmission.org/downloads")!)
                                        .navigationTitle("Downloads")
                                } label: {
                                    Label("Books & PDFs →", systemImage: "books.vertical.fill")
                                }
                                .buttonStyle(SignatureButtonStyle())
                                .pushToLeft()
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                    .background(Color.brown.opacity(0.15))
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
