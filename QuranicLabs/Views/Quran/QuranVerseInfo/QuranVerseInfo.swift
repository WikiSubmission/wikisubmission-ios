import SwiftUI
import SheetKit
import Defaults

struct QuranVerseInfo: View {
    
    var data: Types.Quran.Data?
    
    @EnvironmentObject private var environment: AppEnvironment
    
    @State private var wordByWordData: [Types.Quran.WordByWord] = []
    
    @Default(.arabic) var arabic
    @Default(.bookmarks) var bookmarks
    
    var body: some View {
        if let data = data {
            NavigationStack {
                VStack {
                    content
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .toolbar {
                    HStack(spacing: 0) {
                        NavigationLink {
                            QuranBookmarks()
                        } label: {
                            Label("Bookmarks", systemImage: "bookmark")
                                .labelStyle(.iconOnly)
                        }
                        QuranMenu(data: [data])
                    }
                }
                .navigationTitle("Verse Info")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                verseCard
                buttonRow
                Divider().padding(.vertical, 20)
                wordByWordSection
            }
            .padding()
            .preventHorizontalScroll()
        }
    }
    
    private var verseCardTop: some View {
        VStack {
            let bookmark = bookmarks.first(where: { $0.key == data?.verse_id })
            if let bookmark = bookmark {
                if bookmark.category != nil {
                    Text(bookmark.category ?? "")
                        .fontDesign(.serif)
                        .foregroundStyle(. yellow)
                        .pushToRight()
                }
            }
        }
    }
    
    private var verseCard: some View {
        VStack {
            verseCardTop
            QuranVerseCard(
                id: data!.verse_id,
                removeLinkToDetails: true,
                removeFormatting: true,
                removeContextMenu: true
            )
        }
    }
    
    private var buttonRow: some View {
        FlexStack {
            Button {
                SheetKit().presentWithEnvironment {
                    QuranShareVerses(data: [data!])
                }
            } label: {
                Label("Share/copy...", systemImage: "square.and.arrow.up")
            }
            
            Button {
                if environment.AudioPlayerManager.isPlaying {
                    environment.AudioPlayerManager.player.stop()
                } else {
                    environment.AudioPlayerManager.playVerse(data!.verse_id)
                }
            } label: {
                Label(environment.AudioPlayerManager.isPlaying ? "Stop Audio" : "Play Audio", systemImage: environment.AudioPlayerManager.isPlaying ? "stop.fill" : "play.fill")
            }
            
            Button {
                Task {
                    if let bookmark = bookmarks.first(where: {
                        $0.key == data?.verse_id
                    }) {
                        try? await Utilities.Bookmarks.removeBookmark(bookmark)
                    } else {
                        try? await Utilities.Bookmarks.addBookmark(.init(
                            created_at: Date().ISO8601Format(),
                            updated_at: nil,
                            type: .verse,
                            key: data!.verse_id,
                            category: nil,
                            notes: nil,
                        ))
                        
                        SheetKit().presentWithEnvironment {
                            QuranBookmarks()
                        }
                    }
                }
            } label: {
                let isBookmarked = bookmarks.contains(where: { $0.key == data?.verse_id })
                Label(isBookmarked ? "Remove bookmark" : "Bookmark", systemImage: isBookmarked ? "star.fill" : "star")
                    .foregroundStyle(isBookmarked ? .red : .accent)
            }
        }
        .buttonStyle(SignatureButtonStyle())
        .padding(.top)
    }
    
    private var wordByWordSection: some View {
        Section(header: sectionHeader("WORD BY WORD")) {
            if wordByWordData.count > 0 {
                ForEach(wordByWordData, id: \.self) { i in
                    wordRow(i)
                }
            }
        }
        .onAppear {
            wordByWordData = AppData.Quran.wordByWordData(forVerseID: data!.verse_id) ?? []
        }
    }
    
    private func wordRow(_ i: Types.Quran.WordByWord) -> some View {
        VStack {
            HStack {
                Text(i.english_text)
                Spacer()
                Text("\(i.transliterated_text) / \(i.arabic_text)")
                
                if i.meanings.count > 0 {
                    Button {
                        presentRootWordSheet(i)
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accent)
                    }
                }
            }
            .font(.footnote)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
        }
        .font(.title2)
        .fontWeight(.ultraLight)
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
    }
    
    private func presentRootWordSheet(_ word: Types.Quran.WordByWord) {
        SheetKit().presentWithEnvironment {
            NavigationStack {
                Text(word.root_word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(spacing: 12) {
                        Section {
                            Text(word.verse_id)
                            HStack {
                                Text("\"\(word.english_text)\"")
                                Spacer()
                                Text("\(word.transliterated_text) / \(word.arabic_text)")
                            }
                        }
                        Divider()
                        meaningsSection(word)
                        Divider()
                        allOccurrencesSection(word)
                        Spacer()
                    }
                }
            }
            .padding()
            .presentationDetents([.medium])
            .textSelection(.enabled)
        }
    }
    
    private func meaningsSection(_ word: Types.Quran.WordByWord) -> some View {
        Section(header: sectionHeader("MEANINGS")) {
            HStack {
                Text(word.meanings)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func allOccurrencesSection(_ word: Types.Quran.WordByWord) -> some View {
        AsyncOccurrencesView(rootWord: word.root_word)
    }
    
    private struct AsyncOccurrencesView: View {
        let rootWord: String
        @Default(.arabic) var arabic
        @State private var occurrences: [Types.Quran.WordByWord] = []
        @State private var isLoading: Bool = true

        var body: some View {
            Section {
                if isLoading {
                    ProgressView("Loading occurrences…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else if occurrences.isEmpty {
                    Text("No occurrences found.")
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack {
                        ForEach(occurrences, id: \.global_index) { verse in
                            QuranVerseCard(
                                id: verse.verse_id,
                                linkToChapter: true,
                                highlightArabicWordIndex: verse.word_index
                            )
                            .onAppear {
                                if !arabic { arabic = true }
                            }
                        }
                    }
                }
            } header: {
                Text("OCCURRENCES (\(isLoading ? "…" : "\(occurrences.count == 500 ? "500+" : "\(occurrences.count)")"))")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
            .task {
                await MainActor.run {
                    occurrences = AppData.Quran.versesWithRoot(rootWord) ?? []
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    QuranVerseInfo(data: AppData.Quran.sampleVerse)
        .environmentObject(AppEnvironment.shared)
}
