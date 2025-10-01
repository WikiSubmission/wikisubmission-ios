import SwiftUI
import SheetKit

struct QuranShareVerses: View {
    let data: [Types.Quran.Data]
    
    @State private var selectedVerses: Set<String> = []
    @State private var previewText: String = ""
    
    init(data: [Types.Quran.Data]) {
        self.data = data
        _selectedVerses = State(initialValue: Set(data.map { $0.verse_id }))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !data.isEmpty {
                    selectionSection
                    horizontalActionButtons
                    verseList
                    footerInfo
                } else {
                    Text("No verses available")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .toolbar {
                QuranMenu(data: data, hideShareButton: true)
            }
            .navigationTitle("Share Verses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var selectionSection: some View {
        Section {
            VStack(spacing: 4) {
                if data.count > 1 {
                    selectAllButton.pushToLeft()
                    selectedVersesPreview.pushToLeft()
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 12)
    }
    
    private var selectAllButton: some View {
        Button {
            if selectedVerses.count == data.count {
                selectedVerses.removeAll()
            } else {
                selectedVerses = Set(data.map { $0.verse_id })
            }
        } label: {
            HStack {
                Image(systemName: selectedVerses.count == data.count ? "checkmark.circle.fill" : "checkmark.circle")
                Text("Select All (\(selectedVerses.count))")
            }
        }
        .buttonStyle(SignatureButtonStyle())
    }
    
    private var selectedVersesPreview: some View {
        let orderedSelected = data
            .filter { selectedVerses.contains($0.verse_id) }
            .map { $0.verse_id }
        
        return Text(orderedSelected.joined(separator: ", "))
            .foregroundStyle(.secondary)
            .font(.caption2)
            .lineLimit(4)
    }
    
    private var horizontalActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                copyButton
                shareButton
                previewButton
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var copyButton: some View {
        Button {
            let versesToCopy = data.filter { selectedVerses.contains($0.verse_id) }
            let text = Utilities.formatVersesToText(versesToCopy)
            UIPasteboard.general.string = text
        } label: {
            Label("Copy", systemImage: "doc.on.doc.fill")
        }
        .buttonStyle(SignatureButtonStyle())
    }
    
    private var shareButton: some View {
        Button {
            let versesToShare = data.filter { selectedVerses.contains($0.verse_id) }
            let text = Utilities.formatVersesToText(versesToShare, showAlert: false)
            
            // Ensure share view is top in view hierarchy
            if let topVC = UIApplication.shared.topMostViewController() {
                let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                topVC.present(activityVC, animated: true)
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up.fill")
        }
        .buttonStyle(SignatureButtonStyle())
    }
    
    private var previewButton: some View {
        Button {
            let versesToPreview = data.filter { selectedVerses.contains($0.verse_id) }
            previewText = Utilities.formatVersesToText(versesToPreview, showAlert: false)
            
            SheetKit().presentWithEnvironment {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use this space to preview or select a portion of the text. Any changes to the text will not be saved.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    
                    Divider()
                    
                    TextEditor(text: $previewText)
                        .cornerRadius(8)
                }
                .padding()
                .presentationDetents([.medium, .large])
            }
        } label: {
            Label("Preview Text", systemImage: "eye.fill")
        }
        .buttonStyle(SignatureButtonStyle())
    }
    
    private var verseList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(data, id: \.verse_id) { verse in
                    VerseSelectionRow(
                        verse: verse,
                        isSelected: selectedVerses.contains(verse.verse_id)
                    ) { selected in
                        if selected {
                            selectedVerses.insert(verse.verse_id)
                        } else {
                            selectedVerses.remove(verse.verse_id)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var footerInfo: some View {
        VStack {
            Divider()
                .padding(.bottom, 4)
            Label("Use the menu on the top right to adjust content (e.g. include arabic / footnotes)", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .pushToLeft()
        }
        .padding()
    }
}

struct VerseSelectionRow: View {
    let verse: Types.Quran.Data
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .padding(.vertical, 4)
                
                QuranVerseCard(id: verse.verse_id, removeLinkToDetails: true, removeFormatting: true, removeContextMenu: true)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuranShareVerses(data: AppData.Quran.main.filter { $0.chapter_number == 19 && $0.verse_number > 97 })
        .environmentObject(AppEnvironment.shared)
}
