import SwiftUI

struct Quran_Element_ChapterInfo: View {
    
    var verse: QuranUnified
    
    var body: some View {
        Section {
            HStack {
                Text("Name")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(verse.chapter.title_english)")
            }
            
            HStack {
                Text("Arabic")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(verse.chapter.title_arabic) (\(verse.chapter.title_transliterated))")
            }
            
            HStack {
                Text("Verses")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(verse.chapter.chapter_verses)")
            }
            
            HStack {
                Text("Revelation")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(verse.chapter.revelation_order)")
            }
        }
    }
}
