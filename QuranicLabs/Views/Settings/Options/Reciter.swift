import SwiftUI
import Defaults

struct QuranReciterSelection: View {
    @Default(.quran_reciter) var quranReciter
    @ObservedObject var audioManager = Utilities.Quran.QuranAudioManager.shared
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            ForEach(QuranReciters.allCases, id: \.self) { reciter in
                Button {
                    quranReciter = reciter
                    audioManager.pauseQueuePlayback()
                    audioManager.playCurrentInQueue()
                    dismiss()
                } label: {
                    VStack {
                        HStack {
                            VStack {
                                HStack {
                                    Text(reciter.displayName)
                                        .foregroundStyle(.primary)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text(reciter.speciality)
                                        .foregroundStyle(.gray)
                                        .font(.footnote)
                                    Spacer()
                                }
                            }
                            Spacer()
                            Image(reciter.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .cornerRadius(13)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        .border(Color.accentColor, width: reciter.rawValue == quranReciter.rawValue ? 1.5 : 0)
                        .background(Color.secondary.opacity(0.05))
                        
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .presentationDetents([.medium])
    }
}
