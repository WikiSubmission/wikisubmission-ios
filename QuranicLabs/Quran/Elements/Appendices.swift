import SwiftUI

struct Appendices: View {
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    Image("book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(9)
                        .padding(.top)
                        .padding(.horizontal)
                    Text("Quran: The Final Testament")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("Appendices")
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    Text("Rashad Khalifa, Ph.D.")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        NavigationLink {
                            WebView(url: URL(string: "https://docs.wikisubmission.org/library/books/quran-the-final-testament-introduction")!)
                                .navigationTitle("Introduction")
                        } label: {
                            HStack(spacing: 4) {
                                Text("Introduction")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle())
                        
                        NavigationLink {
                            WebView(url: URL(string: "https://docs.wikisubmission.org/library/books/quran-the-final-testament-appendices")!)
                                .navigationTitle("Appendices")
                        } label: {
                            HStack(spacing: 4) {
                                Text("Appendices 1 - 38 (PDF)")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .buttonStyle(SignatureButtonStyle())
                    }
                    .font(.footnote)
                    
                    ForEach(appendices, id: \.self) { appendix in
                        NavigationLink {
                            WebView(url: URL(string: "https://docs.wikisubmission.org/library/books/quran-the-final-testament-appendix-\(appendix.appendixNumber)")!)
                                .navigationTitle("Appendix \(appendix.appendixNumber)")
                        } label: {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Appendix \(appendix.appendixNumber)")
                                        .fontWeight(.semibold)
                                        .font(.title3)
                                    Text("\(appendix.appendixTitle)")
                                }
                                .padding(.vertical)
                                .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)
                                    .foregroundStyle(.secondary)
                                    .opacity(0.4)
                                    .padding(.bottom, 2)
                            }
                            .padding(.horizontal)
                            .background(Color.secondary.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        .buttonStyle(.plain)
                    }
                }
                .toolbar {
                    NavigationLink {
                        WebView(url: URL(string: "https://docs.wikisubmission.org/library/books/quran-the-final-testament")!)
                            .navigationTitle("Quran: The Final Testament")
                    } label: {
                        Text("Full PDF")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Appendices")
        }
    }
    
    struct Appendix: Hashable {
        let appendixNumber: Int
        let appendixTitle: String
    }
    
    let appendices: [Appendix] = [
        Appendix(appendixNumber: 1, appendixTitle: "One of the Great Miracles [74:35]"),
        Appendix(appendixNumber: 2, appendixTitle: "God's Messenger of the Covenant [3:81]"),
        Appendix(appendixNumber: 3, appendixTitle: "We Made the Quran Easy [54:17]"),
        Appendix(appendixNumber: 4, appendixTitle: "Why Was the Quran Revealed in Arabic?"),
        Appendix(appendixNumber: 5, appendixTitle: "Heaven and Hell"),
        Appendix(appendixNumber: 6, appendixTitle: "Greatness of God"),
        Appendix(appendixNumber: 7, appendixTitle: "Why Were We Created?"),
        Appendix(appendixNumber: 8, appendixTitle: "The Myth of Intercession"),
        Appendix(appendixNumber: 9, appendixTitle: "Abraham: Original Messenger of Submission"),
        Appendix(appendixNumber: 10, appendixTitle: "God's Usage of the Plural Tense"),
        Appendix(appendixNumber: 11, appendixTitle: "The Day of Resurrection"),
        Appendix(appendixNumber: 12, appendixTitle: "Role of the Prophet Muhammad"),
        Appendix(appendixNumber: 13, appendixTitle: "The First Pillar of Submission"),
        Appendix(appendixNumber: 14, appendixTitle: "Predestination"),
        Appendix(appendixNumber: 15, appendixTitle: "Religious Duties: Gift from God"),
        Appendix(appendixNumber: 16, appendixTitle: "Dietary Prohibition"),
        Appendix(appendixNumber: 17, appendixTitle: "Death"),
        Appendix(appendixNumber: 18, appendixTitle: "Quran is All You Need"),
        Appendix(appendixNumber: 19, appendixTitle: "Hadith and Sunna: Satanic Innovations"),
        Appendix(appendixNumber: 20, appendixTitle: "Quran: Unlike Any Other Book"),
        Appendix(appendixNumber: 21, appendixTitle: "Satan: Fallen Angel"),
        Appendix(appendixNumber: 22, appendixTitle: "Jesus"),
        Appendix(appendixNumber: 23, appendixTitle: "Chronological Order of Revelation"),
        Appendix(appendixNumber: 24, appendixTitle: "Two False Verses Removed from the Quran"),
        Appendix(appendixNumber: 25, appendixTitle: "End of the World"),
        Appendix(appendixNumber: 26, appendixTitle: "The Three Messengers of Submission"),
        Appendix(appendixNumber: 27, appendixTitle: "Who Is Your God?"),
        Appendix(appendixNumber: 28, appendixTitle: "Muhammad Wrote God's Revelations With His Own Hand"),
        Appendix(appendixNumber: 29, appendixTitle: "The Missing Basmalah"),
        Appendix(appendixNumber: 30, appendixTitle: "Polygamy"),
        Appendix(appendixNumber: 31, appendixTitle: "Evolution: A Divinely Guided Process"),
        Appendix(appendixNumber: 32, appendixTitle: "The Crucial Age of 40"),
        Appendix(appendixNumber: 33, appendixTitle: "Why Did God Send a Messenger Now?"),
        Appendix(appendixNumber: 34, appendixTitle: "Virginity/Chastity: A Trait of the True Believers"),
        Appendix(appendixNumber: 35, appendixTitle: "Drugs & Alcohol"),
        Appendix(appendixNumber: 36, appendixTitle: "What Price A Great Nation"),
        Appendix(appendixNumber: 37, appendixTitle: "Criminal Justice in Submission"),
        Appendix(appendixNumber: 38, appendixTitle: "The Creator's Signature")
    ]

}
