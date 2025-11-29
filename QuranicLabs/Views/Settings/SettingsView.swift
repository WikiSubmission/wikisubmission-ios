import SwiftUI
import SheetKit
import Defaults
import StoreKit

struct SettingsView: View {
    @Default(.onboarded) private var onboarded
    @State private var showResetConfirmation = false
    @State private var showMailError = false

    @Environment(\.openURL) private var openURL
    
    @Default(.quran_reciter) var reciter
    
    var body: some View {
        NavigationStack {
            List {
                languageSection
                appearanceSection
                previewVerseSection
                readerTogglesSection
                miscalleneousSection
                prayerTimesTogglesSection
                experimentalSection
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
        Group {
            Section(header: Text("Quran Reading")) {
                ArabicToggle()
                SubtitlesToggle()
                FootnotesToggle()
                TransliterationToggle()
                ArabicPositionToggle()
            }
            
            Section {
                UseSerifFontDesignToggle()
            }
            
            NavigationLink {
                NavigationStack {
                    ScrollView {
                        QuranReciterSelection()
                    }
                    .navigationTitle("Reciter")
                }
            } label: {
                HStack {
                    Label("Reciter", systemImage: "waveform.path")
                    Spacer()
                    Text(reciter.displayName)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var prayerTimesTogglesSection: some View {
        Section(header: Text("Prayer Times"), footer: Text("Midpoint method refers to the exact mid-point between noon and sunset, which starts slightly earlier than traditional methods.")) {
            AsrMethodToggle()
        }
    }
    
    private var miscalleneousSection: some View {
        Group {
            Section(header: Text("General")) {
                NavigationLink {
                    NotificationsView()
                } label: {
                    Label("Notifications", systemImage: "bell.fill")
                }
                
                Button {
                    Task {
                        await Utilities.System.checkForAppUpdates(forceCheck: true)
                    }
                } label: {
                    Label("Check for updates", systemImage: "rectangle.grid.2x2.fill")
                }
            }
        }
    }
    
    private var experimentalSection: some View {
        Section(header: Text("Experimental Features"), footer: Text("These features are still under development and will be made generally available only once proven stable.")) {
            QiblaToggle()
        }
    }

    private var appActionsSection: some View {
        Group {
            Section(footer: Text("Our email is developer@wikisubmission.org.")) {
                Button {
                    let subject = "Re: iOS App".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Re: iOS App"
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
            }
            
            Section(header: Text("Support WikiSubmission"), footer: Text("We are a registered 501(c)(3) nonprofit. Your support helps us continue to develop open-source technology in the cause of God.")) {
                Button {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        AppStore.requestReview(in: scene)
                    } else {
                        openURL(URL(string: Info.appStoreURL)!)
                    }
                } label: {
                    Label("Review the App", systemImage: "star.fill")
                }
                
                Button {
                    openURL(URL(string: Info.appStoreURL)!)
                } label: {
                    Label("Open in App Store", systemImage: "globe.fill")
                }
                
                Button {
                    openURL(URL(string: "https://wikisubmission.org/donate")!)
                } label: {
                    Label("Donate", systemImage: "heart.fill")
                }
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
            linkButton(title: "Web Reader", url: "https://wikisubmission.org/quran")
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
