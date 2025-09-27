import SwiftUI
import SheetKit
import Defaults

struct SettingsView: View {
    @Default(.onboarded) private var onboarded
    @State private var showResetConfirmation = false
    @State private var showMailError = false

    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            List {
                SignIn(removeFormatting: true)
                    .padding(.vertical)
                languageSection
                appearanceSection
                previewVerseSection
                readerTogglesSection
                prayerTimesTogglesSection
                miscalleneousSection
                appActionsSection
                appInfoSection
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Settings")
        }
    }

    private var languageSection: some View {
        Section(header: Text("Language"), footer: translatorsFooter) {
            PrimaryLanguagePicker()
            SecondaryLanguagePicker()
        }
    }

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            FontSizeSelector()
        }
    }

    private var previewVerseSection: some View {
        Section("Preview Verse") {
            QuranVerseCard(id: "2:20", removeLinkToDetails: true, removeFormatting: true)
        }
    }

    private var readerTogglesSection: some View {
        Section(header: Text("Reader")) {
            ArabicToggle()
            SubtitlesToggle()
            FootnotesToggle()
            TransliterationToggle()
            ArabicPositionToggle()
        }
    }
    
    private var prayerTimesTogglesSection: some View {
        Section(header: Text("Prayer Times")) {
            AsrMethodToggle()
        }
    }
    
    private var miscalleneousSection: some View {
        Section() {
            NavigationLink {
                NotificationsView()
            } label: {
                Label("Notifications", systemImage: "bell.fill")
            }
        }
    }

    private var appActionsSection: some View {
        Section(header: Text("App Actions")) {
            Button {
                let subject = "Regarding App".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Regarding App"
                if let url = URL(string: "mailto:\(Info.contactEmail)?subject=\(subject)"),
                   UIApplication.shared.canOpenURL(url) {
                    openURL(url)
                } else {
                    showMailError = true
                }
            } label: {
                Label("Contact / Inquiries", systemImage: "envelope.fill")
            }
            .alert("Cannot open Mail app", isPresented: $showMailError) {
                Button("OK", role: .cancel) {}
            }

            Button(role: .destructive) { showResetConfirmation = true } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.red)
            }
            .confirmationDialog(
                "Are you sure you want to reset the App?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    Task {
                        await Utilities.System.resetTasks()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var appInfoSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text("\(Info.version), Build \(Info.build)")
                    .foregroundStyle(.secondary)
            }
            linkButton(title: "Web Reader", url: "https://wikisubmission.org")
            linkButton(title: "Developer Discord", url: Info.developerDiscordLink)
            linkButton(title: "GitHub", url: "https://github.com/wikisubmission")
        }
    }

    private var translatorsFooter: some View {
        Button("Translators") {
            SheetKit().presentWithEnvironment {
                NavigationStack {
                    ScrollView {
                        Text("""
        Original English edition by Rashad Khalifa, Ph.D.

        For non-English translations: please refer to their original versions / PDFs. This app only contains partial extractions.

        Turkish edition: Teslim Olanlar
        French edition: Masjid Paris
        German edition: SubmitterTech
        Persian edition: Masjid Tucson
        Russian edition: Madina & Mila Komarnisky
        Swedish edition: swedish.submission.info
        Bahasa/Malay: submission.org
        Tamil & Hindi: kadavulmattum.org
        """)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .navigationTitle("Translators")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .font(.footnote)
    }

    private func linkButton(title: String, url: String) -> some View {
        Button {
            openURL(URL(string: url)!)
        } label: {
            HStack {
                Label(title, systemImage: title == "GitHub" ? "hammer.circle.fill" : "globe.asia.australia.fill")
                Spacer()
                Image(systemName: "arrow.up.forward.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.shared)
}
