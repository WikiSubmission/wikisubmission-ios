import SwiftUI

struct ResourcesView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    LargeCard(
                        title: "Quran Talk Blog",
                        subtitle: "Reflections and unique insights from the Quran",
                        image: "qurantalk"
                    ) {
                        WebView(url: URL(string: "https://qurantalkblog.com")!)
                            .navigationTitle("Quran Talk Blog")
                    }
                    
                    LargeCard(
                        title: "Submission Archives",
                        subtitle: "Useful videos and community archives",
                        image: "submissionarchives"
                    ) {
                        WebView(url: URL(string: "https://youtube.com/@SubmissionArchives")!)
                            .navigationTitle("Submission Archives")
                    }
                    
                    LargeCard(
                        title: "Submission Server",
                        subtitle: "Access the worldwide Submitter community",
                        image: "19"
                    ) {
                        WebView(url: URL(string: "https://discord.gg/submissionserver")!)
                            .navigationTitle("Submission Server")
                    }
                    
                    HStack {
                        NavigationLink {
                            WebView(url: URL(string: "https://wikisubmission.org/downloads")!)
                                .navigationTitle("Books & PDFs")
                        } label: {
                            Label("Books & PDFs →", systemImage: "books.vertical.fill")
                        }
                        .buttonStyle(SignatureButtonStyle())
                        .pushToLeft()
                    }
                    .padding(.top)
                }
                .padding()

            }
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ResourcesView()
}
