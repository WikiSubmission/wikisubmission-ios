import SwiftUI
import Defaults
import SheetKit

struct QuranNowPlayingBar: View {
    @ObservedObject var audioManager = Utilities.Quran.QuranAudioManager.shared
    @State private var presentReciterSelection = false
    @Default(.primary_language) var primaryLanguage
    @Default(.quran_reciter) var quranReciter
    var body: some View {
        if audioManager.isQueueActive, let verse = audioManager.currentVerse {
            Button {
                SheetKit().presentWithEnvironment {
                    NavigationStack {
                        QuranReaderView(chapter: verse.chapter_number, scrollToVerseID: verse.verse_id)
                    }
                }
            } label: {
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        // Verse info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sura \(verse.chapter_number), \(verse.getChapterTitle(for: .english))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(verse.chapter_number):\(verse.verse_number)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Playback controls
                        HStack(spacing: 12) {
                            Button(action: { audioManager.previousInQueue() }) {
                                Image(systemName: "backward.fill")
                                    .font(.title3)
                            }
                            Button(action: {
                                if audioManager.isPlaying {
                                    audioManager.pauseQueuePlayback()
                                } else {
                                    audioManager.playCurrentInQueue()
                                }
                            }) {
                                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                            }
                            Button(action: { audioManager.nextInQueue() }) {
                                Image(systemName: "forward.fill")
                                    .font(.title3)
                            }
                            Button {
                                presentReciterSelection = true
                            } label: {
                                Image(quranReciter.rawValue)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            Button(action: { audioManager.stopQueue() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 7, y: 3)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 60)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: audioManager.isQueueActive)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $presentReciterSelection) {
                QuranReciterSelection()
            }
        }
    }
}

#if DEBUG
#Preview {
    QuranNowPlayingBar()
        .environmentObject(AppEnvironment.shared)
}
#endif
