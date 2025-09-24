import SwiftUI
import SheetKit
import Defaults

struct QuranVerseCard: View {
    let id: String
    var highlight = ""
    var linkToChapter = false
    var removeLinkToDetails = false
    var removeFormatting = false
    var removeContextMenu = false
    var removeBookmarkedIcon = false
    var isScrolledTo = false
    var highlightArabicWordIndex: Int? = nil
    
    @Default(.arabic) private var arabic
    @Default(.subtitles) private var subtitles
    @Default(.footnotes) private var footnotes
    @Default(.transliteration) private var transliteration
    @Default(.arabic_on_side) private var arabicOnSide
    @Default(.primary_language) private var primaryLanguage
    @Default(.secondary_language) private var secondaryLanguage
    @Default(.font_size) private var fontSize

    @EnvironmentObject private var environment: AppEnvironment

    @Environment(\.colorScheme) private var theme
    
    @State private var data: Types.Quran.Data?
    @State private var showHighlight = false
    
    var body: some View {
        VStack {
            if let data = data {
                ConditionalNavigationLink(
                    isActive: linkToChapter || (!removeLinkToDetails && !linkToChapter),
                    destination: VStack {
                        if !linkToChapter {
                            QuranVerseInfo(data: data)
                        } else {
                            QuranReaderView(chapter: data.chapter_number, scrollToVerseID: data.verse_id)
                        }
                    }
                ) {
                    content(data: data)
                        .padding(removeFormatting ? 0 : 12)
                        .background(removeFormatting ? Color.clear : Color.secondary.opacity(showHighlight ? 0.14 : theme == .dark ? 0.06 : 0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .task {
                            if isScrolledTo {
                                showHighlight = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation {
                                        showHighlight = false
                                    }
                                }
                            }
                        }
                        .textSelection(.enabled)
                        .conditionalContextMenu(remove: removeContextMenu) {
                            Button {
                                SheetKit().presentWithEnvironment { QuranShareVerses(data: [data]) }
                            } label: {
                                Label("Copy/Share...", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                Task {
                                    let bookmark = environment.BookmarkManager.get(verseID: data.verse_id)
                                    if (bookmark == nil) {
                                        await environment.BookmarkManager.addVerse(data.verse_id)
                                    } else {
                                        await environment.BookmarkManager.remove(bookmarkID: bookmark!.id)
                                    }
                                }
                            } label: {
                                let isBookmarked = environment.BookmarkManager.isBookmarked(verseID: data.verse_id)
                                Label(isBookmarked ? "Remove bookmark" : "Bookmark", systemImage: isBookmarked ? "star.fill" : "star")
                                    .foregroundStyle(isBookmarked ? .red : .accent)
                            }
                            
                            QuranMenu()
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.06))
                    .frame(height: 150)
                    .shimmering()
            }
        }
        .onAppear {
            Task {
                DispatchQueue.main.async {
                    self.data = AppData.Quran.verseByID(id)
                }
            }
        }
    }

    @ViewBuilder private func content(data: Types.Quran.Data) -> some View {
        VStack(spacing: 8) {
            verseID(data: data)
            subtitle(data: data)
            primaryAndArabicText(data: data)
                .fontDesign(.serif)
            secondaryText(data: data)
            transliteration(data: data)
            footnote(data: data)
        }
    }

    @ViewBuilder private func verseID(data: Types.Quran.Data) -> some View {
        let parts = data.verse_id.split(separator: ":")
        HStack(spacing: 1) {
            Text(parts[0])
            Text(":")
                .fontWeight(.light)
                .padding(.bottom, 2)
                .padding(.horizontal, 1)
            Text(parts[1])
                .foregroundStyle(.secondary)
            if !removeBookmarkedIcon && environment.BookmarkManager.isBookmarked(verseID: data.verse_id) {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.orange)
                    .padding(.leading, 4)
            }
            HStack {
                Spacer()
                if linkToChapter {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)
                        .fontWeight(.light)
                }
            }
        }
        .font(.system(size: CGFloat(fontSize + 6)))
        .fontWeight(.semibold)
    }

    @ViewBuilder private func subtitle(data: Types.Quran.Data) -> some View {
        if subtitles, let subtitleText = data.getSubtitle(for: primaryLanguage) {
            HStack { ConditionalHighlight(text: subtitleText, query: highlight) }
                .font(.system(size: CGFloat(fontSize - 4)))
                .foregroundStyle(.accent)
                .italic()
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder private func primaryAndArabicText(data: Types.Quran.Data) -> some View {
        Group {
            if arabicOnSide {
                HStack(alignment: .top, spacing: 12) {
                    primaryText(data: data)
                        .fixedSize(horizontal: false, vertical: true)
                    arabicText(data: data)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    primaryText(data: data)
                    arabicText(data: data)
                }
            }
        }
    }

    @ViewBuilder private func primaryText(data: Types.Quran.Data) -> some View {
        let text = data.getPrimaryText(for: primaryLanguage)
        HStack {
            ConditionalHighlight(text: text, query: highlight)
            Spacer()
        }
        .font(.system(size: CGFloat(primaryLanguage == .persian ? fontSize + 2 : fontSize)))
        .multilineTextAlignment(primaryLanguage == .persian ? .trailing : .leading)
    }

    @ViewBuilder private func arabicText(data: Types.Quran.Data) -> some View {
        if arabic {
            if let highlightIndex = highlightArabicWordIndex {
                let arabicWordByWord = data.getWordByWord()
                if !arabicWordByWord.isEmpty {
                    FlexStack(horizontalSpacing: 9) {
                        ForEach(arabicWordByWord, id: \.word_index) { i in
                            Text(i.arabic_text)
                                .font(.system(size: CGFloat(primaryLanguage == .persian ? fontSize + 2 : fontSize)))
                                .fontDesign(.default)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.red.opacity(i.word_index == highlightIndex ? 0.15 : 0))
                                        .padding(-6)
                                )
                        }
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                    .multilineTextAlignment(.trailing)
                }
            } else {
                // Show the full Arabic text without highlighting
                HStack {
                    Spacer()
                    Text(data.verse_text_arabic)
                        .font(.system(size: CGFloat(fontSize + 1)))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    @ViewBuilder private func secondaryText(data: Types.Quran.Data) -> some View {
        if let secondaryText = data.getSecondaryText(for: secondaryLanguage) {
            HStack {
                ConditionalHighlight(text: secondaryText, query: highlight)
                Spacer()
            }
            .font(.system(size: CGFloat(primaryLanguage == .persian ? fontSize + 2 : fontSize)))
            .multilineTextAlignment(secondaryLanguage == .persian ? .trailing : .leading)
            .foregroundStyle(.primary.opacity(0.9))
        }
    }

    @ViewBuilder private func transliteration(data: Types.Quran.Data) -> some View {
        if transliteration {
            let transliterationText = data.verse_text_transliterated
            HStack {
                Text(transliterationText)
                    .foregroundStyle(.secondary.opacity(0.8))
                    .font(.system(size: CGFloat(fontSize - 2)))
                Spacer()
            }
        }
    }

    @ViewBuilder private func footnote(data: Types.Quran.Data) -> some View {
        if footnotes, let footnoteText = data.getFootnote(for: primaryLanguage) {
            HStack {
                ConditionalHighlight(text: footnoteText, query: highlight)
                Spacer()
            }
            .font(.system(size: CGFloat(fontSize - 5)))
            .foregroundStyle(.secondary)
            .italic()
        }
    }
}

extension View {
    func shimmering() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                GeometryReader { geometry in
                    let width = geometry.size.width
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.4), Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: -width)
                    .frame(width: width, height: geometry.size.height)
                    .modifier(ShimmerAnimation(width: width))
                }
            )
    }
}

private struct ShimmerAnimation: ViewModifier {
    @State private var xOffset: CGFloat = 0
    let width: CGFloat
    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    xOffset = width * 2
                }
            }
            .offset(x: xOffset - width)
    }
}


#Preview {
    QuranVerseCard_Preview()
        .environmentObject(AppEnvironment.shared)
}
