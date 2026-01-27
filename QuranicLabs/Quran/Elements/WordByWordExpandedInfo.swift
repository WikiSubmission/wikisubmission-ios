import SwiftUI
import SwiftData

struct Quran_Element_WordExpandedInfo: View {
    @Environment(\.modelContext) private var modelContext

    let verse: QuranUnified
    let word: QuranWordByWordSD

    @State private var relatedVerses: [QuranWordByWordSD] = []
    @State private var loadingState: LoadingState = .idle
    @State private var totalCount: Int = 0
    @State private var selectMode = QuranSelectMode()

    private let maxResults = 500

    enum LoadingState {
        case idle, loading, loaded, error
    }

    var body: some View {
        List {
            headerSection
                .textSelection(.enabled)
            relatedVersesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Word \(word.word_index) in \(word.verse_id)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            selectMode.canSelect = true
            await loadRelatedVerses()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if selectMode.canSelect && selectMode.selection.count > 0 {
                        Quran_Element_SelectVersesActions(selectMode: selectMode, toolbarMode: true)
                    }
                    Quran_Element_SelectVersesTrigger(selectMode: selectMode, toolbarContext: true)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(spacing: 0) {
                // Word display
                VStack(spacing: 16) {
                    // Arabic word - prominent display
                    Text(word.arabic)
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(.primary)

                    // Transliteration
                    Text(word.transliterated)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 40, height: 2)
                        .clipShape(Capsule())

                    // English meaning
                    Text("\"\(word.english)\"")
                        .font(.body)
                        .italic()
                        .foregroundStyle(.accent)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                // Root info section
                if let root = word.root_word, !root.isEmpty {
                    VStack(spacing: 12) {
                        // Root pill
                        HStack(spacing: 8) {
                            Image(systemName: "character.textbox")
                                .font(.subheadline)
                                .foregroundStyle(.accent)

                            Text("Root:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(root)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Meanings card
                        if let meanings = word.meanings, !meanings.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Meanings", systemImage: "text.book.closed")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)

                                Text(meanings)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
    }

    // MARK: - Related Verses Section

    private var relatedVersesSection: some View {
        Section {
            switch loadingState {
            case .idle, .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)

            case .error:
                Text("Failed to load related verses")
                    .foregroundStyle(.secondary)

            case .loaded:
                if relatedVerses.isEmpty {
                    Text("No other verses found with this root")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(relatedVerses, id: \.persistentModelID) { relatedWord in
                        relatedVerseRow(relatedWord)
                    }
                }
            }
        } header: {
            Text(sectionTitle)
        }
    }

    private func relatedVerseRow(_ relatedWord: QuranWordByWordSD) -> some View {
        Quran_Element_VerseCard(
            unified: QuranUnified(from: relatedWord, context: modelContext),
            options: .init(
                highlightArabicWordIndices: [relatedWord.word_index],
                selectMode: selectMode,
                linkToChapterContext: true,
                linkShouldNotReroute: true
            )
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }

    private var sectionTitle: String {
        switch loadingState {
        case .idle, .loading:
            return "Finding related verses..."
        case .error:
            return "Related Verses"
        case .loaded:
            if totalCount > maxResults {
                return "\(maxResults)+ verses with the same root"
            } else if totalCount > 0 {
                return "\(totalCount) verses with the same root"
            } else {
                return "Related Verses"
            }
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadRelatedVerses() async {
        guard let rootWord = word.root_word, !rootWord.isEmpty else {
            loadingState = .loaded
            return
        }

        loadingState = .loading

        do {
            let descriptor = FetchDescriptor<QuranWordByWordSD>(
                predicate: #Predicate { $0.root_word == rootWord },
                sortBy: [
                    SortDescriptor(\.verse_index),
                    SortDescriptor(\.word_index)
                ]
            )

            let allMatches = try modelContext.fetch(descriptor)

            // Deduplicate by verse_id, keeping first word occurrence per verse
            var seenVerseIDs = Set<String>()
            var uniqueVerses: [QuranWordByWordSD] = []

            for match in allMatches {
                if seenVerseIDs.insert(match.verse_id).inserted {
                    if uniqueVerses.count < maxResults {
                        uniqueVerses.append(match)
                    }
                }
            }

            relatedVerses = uniqueVerses
            totalCount = seenVerseIDs.count
            loadingState = .loaded
        } catch {
            loadingState = .error
        }
    }
}
