import SwiftUI

struct Music_LyricsSheet: View {
    let trackTitle: String
    let artistName: String
    let lyrics: String
    let colorSeed: UUID?

    @Environment(\.dismiss) private var dismiss

    private var theme: MusicColorTheme {
        MusicColorTheme.generate(seed: colorSeed)
    }

    private var parsedLyrics: [LyricSection] {
        parseLyrics(lyrics)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Lyrics content
                    lyricsContent
                }
                .padding()
                .padding(.bottom, 40)
                .textSelection(.enabled)
            }
            .background(theme.cardGradient.opacity(0.3))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.artworkGradient)
                    .frame(width: 100, height: 100)

                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
            }
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

            // Track info
            VStack(spacing: 4) {
                Text(trackTitle)
                    .font(DS.Typography.titleMD)
                    .multilineTextAlignment(.center)

                Text(artistName)
                    .font(DS.Typography.titleSM)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(.top, 20)
    }

    // MARK: - Lyrics Content

    private var lyricsContent: some View {
        VStack(alignment: .center, spacing: 20) {
            ForEach(parsedLyrics) { section in
                VStack(spacing: 12) {
                    // Section header (if any)
                    if let header = section.header {
                        Text(header)
                            .font(DS.Typography.body)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .padding(.top, 8)
                    }

                    // Lyrics lines
                    ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(DS.Typography.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary.opacity(0.9))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Parsing

    private func parseLyrics(_ raw: String) -> [LyricSection] {
        var sections: [LyricSection] = []
        var currentHeader: String? = nil
        var currentLines: [String] = []

        let lines = raw.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if it's a section header like [Verse 1] or [Chorus]
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                // Save previous section if it has content
                if !currentLines.isEmpty || currentHeader != nil {
                    sections.append(LyricSection(
                        header: currentHeader,
                        lines: currentLines.filter { !$0.isEmpty }
                    ))
                }

                // Start new section
                currentHeader = String(trimmed.dropFirst().dropLast())
                currentLines = []
            } else if !trimmed.isEmpty {
                currentLines.append(trimmed)
            } else if !currentLines.isEmpty {
                // Empty line within section - preserve as line break indicator
                currentLines.append("")
            }
        }

        // Last section
        if !currentLines.isEmpty || currentHeader != nil {
            sections.append(LyricSection(
                header: currentHeader,
                lines: currentLines.filter { !$0.isEmpty }
            ))
        }

        return sections
    }
}

// MARK: - Lyric Section Model

private struct LyricSection: Identifiable, Hashable {
    let id = UUID()
    let header: String?
    let lines: [String]
}

// MARK: - Preview

#Preview {
    Music_LyricsSheet(
        trackTitle: "Submit",
        artistName: "Artist Name",
        lyrics: """
        [Verse 1]
        Every moment
        A hidden test
        Joy or pain
        Both are blessed

        [Chorus]
        Submit
        Be content
        With what He sends
        Submit
        Accept His will
        The trial ends
        """,
        colorSeed: UUID()
    )
}
