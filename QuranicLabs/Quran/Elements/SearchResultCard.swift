import SwiftUI
import Defaults

struct Quran_Element_SearchResultCard: View {
    let result: QuranSearchResultItem
    let highlightPhrase: String
    var selectMode: QuranSelectMode? = nil

    @Default(.font_size) var fontSize
    @Default(.quran_primary_language) var primaryLanguage

    var body: some View {
        switch result.hitType {
        case .index, .text:
            fullVerseCard
        case .chapter:
            chapterCard
        case .subtitle:
            subtitleCard
        case .footnote:
            footnoteCard
        }
    }

    private var fullVerseCard: some View {
        Quran_Element_VerseCard(
            unified: result.unified,
            options: .init(
                highlightPhrase: highlightPhrase,
                selectMode: selectMode,
                linkToChapterContext: true
            )
        )
    }

    @ViewBuilder
    private var chapterCard: some View {
        if let chapter = result.matchedChapter {
            Quran_Element_ChapterCard(
                chapter: chapter,
                highlightPhrase: highlightPhrase
            )
        }
    }

    private var subtitleCard: some View {
        Button {
            if selectMode?.isActive == true {
                toggleSelection()
            } else {
                Router.shared.push(.chapter(
                    chapterNumber: result.unified.index.chapter_number,
                    scrollToVerseNumber: result.unified.index.verse_number
                ))
            }
        } label: {
            HStack {
                // [Select button: if select is active]
                if let selectMode = selectMode, selectMode.isActive {
                    Button(action: toggleSelection) {
                        Image(systemName: selectMode.selection.contains(result.unified) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectMode.selection.contains(result.unified) ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Header row
                    HStack {
                        Label("Subtitle", systemImage: "text.badge.star")
                            .font(.caption)
                            .foregroundStyle(.accent)

                        Spacer()

                        verseBadge
                    }

                    // Subtitle content
                    if let subtitle = result.unified.subtitle {
                        ConditionalHighlight(
                            text: subtitle.getTextInUserLanguage(),
                            query: highlightPhrase
                        )
                        .font(.system(size: CGFloat(fontSize) - 4))
                        .environment(\.layoutDirection, primaryLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                Color.secondary.opacity(0.06)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footnote Card (Watered-Down)

    private var footnoteCard: some View {
        Button {
            if selectMode?.isActive == true {
                toggleSelection()
            } else {
                Router.shared.push(.chapter(
                    chapterNumber: result.unified.index.chapter_number,
                    scrollToVerseNumber: result.unified.index.verse_number
                ))
            }
        } label: {
            HStack {
                // [Select button: if select is active]
                if let selectMode = selectMode, selectMode.isActive {
                    Button(action: toggleSelection) {
                        Image(systemName: selectMode.selection.contains(result.unified) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectMode.selection.contains(result.unified) ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Header row
                    HStack {
                        Label("Footnote", systemImage: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        verseBadge
                    }
                    
                    // Footnote content
                    if let footnote = result.unified.footnote {
                        ConditionalHighlight(
                            text: footnote.getTextInUserLanguage(),
                            query: highlightPhrase
                        )
                        .font(.system(size: CGFloat(fontSize) - 4))
                        .italic()
                        .foregroundStyle(.secondary)
                        .environment(\.layoutDirection, primaryLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                Color.secondary.opacity(0.06)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var verseBadge: some View {
        HStack {
            HStack(spacing: 1) {
                Text("\(result.unified.index.chapter_number)")
                Text(":")
                Text("\(result.unified.index.verse_number)")
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .font(.caption)
    }
    
    private func toggleSelection() {
        guard let selectMode = selectMode else { return }
        if selectMode.selection.contains(result.unified) {
            selectMode.removeSelection(result.unified)
        } else {
            selectMode.addSelection(result.unified)
        }
    }
}
