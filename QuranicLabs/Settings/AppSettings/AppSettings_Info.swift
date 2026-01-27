import SwiftUI

struct AppSettings_Info: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            openURL(URL(string: "mailto:\(About.contactEmail)")!)
        } label: {
            Label("Contact / Inquiries", systemImage: "envelope")
        }
        
        Button {
            openURL(URL(string: About.developerDiscordLink)!)
        } label: {
            Label("Developer Discord", systemImage: "hand.wave")
        }
        
        Button {
            openURL(URL(string: "https://wikisubmission.org")!)
        } label: {
            Label("Our Website", systemImage: "globe")
        }
    }
}
