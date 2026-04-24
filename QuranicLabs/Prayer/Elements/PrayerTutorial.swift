import SwiftUI

struct Prayer_Element_PrayerTutorial: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [TutorialPage] = [
        .intro,
        .ablution,
        .direction,
        .positions,
        .fatiha,
        .tashahhud,
        .prayerUnits,
        .friday
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            pageContent(for: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Custom page indicator and navigation
                    bottomNavigation
                }
            }
            .navigationTitle("Contact Prayer Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        VStack(spacing: 16) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            // Navigation buttons
            HStack(spacing: 16) {
                Button {
                    withAnimation {
                        currentPage = max(0, currentPage - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(DS.Typography.titleSM)
                        .frame(width: 50, height: 44)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentPage == 0)
                .opacity(currentPage == 0 ? 0.4 : 1)

                // Page title
                Text(pages[currentPage].title)
                    .font(DS.Typography.label)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                Button {
                    withAnimation {
                        currentPage = min(pages.count - 1, currentPage + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(DS.Typography.titleSM)
                        .frame(width: 50, height: 44)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentPage == pages.count - 1)
                .opacity(currentPage == pages.count - 1 ? 0.4 : 1)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }

    // MARK: - Page Content

    @ViewBuilder
    private func pageContent(for page: TutorialPage) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                switch page {
                case .intro:
                    introPage
                case .ablution:
                    ablutionPage
                case .direction:
                    directionPage
                case .positions:
                    positionsPage
                case .fatiha:
                    fatihaPage
                case .tashahhud:
                    tashahhudPage
                case .prayerUnits:
                    prayerUnitsPage
                case .friday:
                    fridayPage
                }
            }
            .padding()
            .padding(.bottom, 60)
        }
    }

    // MARK: - Introduction Page

    private var introPage: some View {
        VStack(spacing: 24) {
            // Hero
            VStack(spacing: 16) {
                Image("wikisubmission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .font(.system(size: 60))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("The Contact Prayers")
                    .font(DS.Typography.heroMD)
            }
            .padding(.top, 20)

            // Description
            tutorialCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Contact Prayers (Salat) are the most important duty in Submission (Islam). They provide the opportunity to connect directly with God five times a day.")

                    Text("The five daily prayers are:")
                        .fontWeight(.medium)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        prayerTimeRow(name: "Dawn", arabic: "Fajr", units: 2, icon: "sunrise")
                        prayerTimeRow(name: "Noon", arabic: "Dhuhr", units: 4, icon: "sun.max")
                        prayerTimeRow(name: "Afternoon", arabic: "Asr", units: 4, icon: "sun.haze")
                        prayerTimeRow(name: "Sunset", arabic: "Maghrib", units: 3, icon: "sunset")
                        prayerTimeRow(name: "Night", arabic: "Isha", units: 4, icon: "moon.stars")
                    }
                }
            }

            tutorialHighlight(
                icon: "sparkles",
                title: "Mathematical Sign",
                text: "The units (2, 4, 4, 3, 4) form 24434, which is 19 × 1286"
            )
        }
    }

    private func prayerTimeRow(name: String, arabic: String, units: Int, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)

            Text(name)
                .fontWeight(.medium)

            Text("(\(arabic))")
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(units) units")
                .font(DS.Typography.bodySM)
                .foregroundStyle(.secondary)
        }
        .font(DS.Typography.bodySM)
    }

    // MARK: - Ablution Page

    private var ablutionPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.cyan)

                Text("The Ablution")
                    .font(DS.Typography.titleLG)

                Text("Wudu")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Verse reference
            tutorialHighlight(
                icon: "book.closed",
                title: "Quran 5:6",
                text: "\"O you who believe, when you observe the Contact Prayers, you shall wash your faces, wash your arms to the elbows, wipe your heads, and wash your feet to the ankles.\""
            )

            // Steps
            tutorialCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Four Steps")
                        .font(DS.Typography.titleSM)

                    ablutionStep(number: 1, title: "Wash your face", icon: "face.smiling")
                    ablutionStep(number: 2, title: "Wash your arms to the elbows", icon: "hand.raised")
                    ablutionStep(number: 3, title: "Wipe your head with wet hands", icon: "brain.head.profile")
                    ablutionStep(number: 4, title: "Wash your feet to the ankles", icon: "shoe")
                }
            }

            // Dry ablution
            tutorialCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Dry Ablution (Tayammum)", systemImage: "leaf")
                        .font(DS.Typography.titleSM)
                        .foregroundStyle(.orange)

                    Text("If water is unavailable or harmful, touch clean soil and wipe your face and hands.")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)
                }
            }

            // What nullifies
            tutorialCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Ablution is Nullified By", systemImage: "exclamationmark.triangle")
                        .font(DS.Typography.titleSM)
                        .foregroundStyle(.red)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("• Using the bathroom")
                        Text("• Passing gas")
                        Text("• Sleep")
                    }
                    .font(DS.Typography.bodySM)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func ablutionStep(number: Int, title: String, icon: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text("\(number)")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.label)
            }

            Spacer()

            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Direction Page

    private var directionPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)

                Text("Direction")
                    .font(DS.Typography.titleLG)

                Text("Qiblah")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            tutorialCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Face Mecca")
                        .font(DS.Typography.titleSM)

                    Text("God decrees that all Submitters face the same direction when observing the Contact Prayers. This direction is toward the Sacred Mosque (Kaaba) in Mecca.")
                        .foregroundStyle(.secondary)
                }
            }

            // Intention
            tutorialCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label("State Your Intention", systemImage: "text.bubble")
                        .font(DS.Typography.titleSM)

                    Text("Before starting, secretly or audibly state your intention in your own language:")
                        .foregroundStyle(.secondary)

                    Text("\"I intend to observe the [Dawn/Noon/Afternoon/Sunset/Night] prayer.\"")
                        .font(DS.Typography.quote)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Voice
            tutorialHighlight(
                icon: "speaker.wave.2",
                title: "Voice Level",
                text: "Maintain an intermediate tone—\"not too loud, nor too secretly\" (17:110)"
            )
        }
    }

    // MARK: - Positions Page

    private var positionsPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple)

                Text("Prayer Positions")
                    .font(DS.Typography.titleLG)

                Text("One Unit (Rak'ah)")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Positions
            VStack(spacing: 12) {
                positionCard(
                    number: 1,
                    title: "Opening Takbir",
                    arabic: "Allahu Akbar",
                    meaning: "God is Great",
                    description: "Raise hands to sides of face, thumbs touch ears, palms forward. Lower hands while saying the words.",
                    icon: "hand.raised"
                )

                positionCard(
                    number: 2,
                    title: "Standing",
                    arabic: "Qiyam",
                    meaning: "Standing Position",
                    description: "Stand upright with arms at sides or left hand on stomach with right on top. Recite Al-Fatiha.",
                    icon: "arrow.up"
                )

                positionCard(
                    number: 3,
                    title: "Bowing",
                    arabic: "Rukoo'",
                    meaning: "Bow from waist",
                    description: "Say \"Allahu Akbar\", bow with straight knees, hands on knees. Say \"Subhaana Rabbiyal 'Azeem\" (God be glorified).",
                    icon: "arrow.down.right"
                )

                positionCard(
                    number: 4,
                    title: "Rising",
                    arabic: "I'tidal",
                    meaning: "Standing briefly",
                    description: "Stand upright saying \"Sami 'Allahu Liman Hamidah\" (God responds to those who praise Him).",
                    icon: "arrow.up.left"
                )

                positionCard(
                    number: 5,
                    title: "Prostration",
                    arabic: "Sujood",
                    meaning: "Forehead to ground",
                    description: "Say \"Allahu Akbar\", place forehead on floor. Say \"Subhaana Rabbiyal A'laa\" (God be glorified).",
                    icon: "arrow.down.to.line"
                )

                positionCard(
                    number: 6,
                    title: "Sitting",
                    arabic: "Jalsah",
                    meaning: "Brief sitting",
                    description: "Sit briefly between prostrations saying \"Allahu Akbar\".",
                    icon: "arrow.up.to.line"
                )

                positionCard(
                    number: 7,
                    title: "Second Prostration",
                    arabic: "Sujood",
                    meaning: "Forehead to ground",
                    description: "Perform second prostration same as the first. This completes one unit (Rak'ah).",
                    icon: "arrow.down.to.line"
                )
            }
        }
    }

    private func positionCard(number: Int, title: String, arabic: String, meaning: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(DS.Typography.label)

                    Spacer()

                    Image(systemName: icon)
                        .foregroundStyle(.purple.opacity(0.7))
                }

                Text(arabic)
                    .font(DS.Typography.caption)
                    .foregroundStyle(Color.accentColor)

                Text(description)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Al-Fatiha Page

    private var fatihaPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)

                Text("Al-Fatiha")
                    .font(DS.Typography.titleLG)

                Text("The Key")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            tutorialHighlight(
                icon: "info.circle",
                title: "Recited in Arabic",
                text: "Al-Fatiha is recited in every unit (Rak'ah) of prayer, in Arabic only."
            )

            // Verses
            VStack(spacing: 8) {
                fatihaVerse(
                    arabic: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                    transliteration: "Bismil-laahir-Rahmaanir-Raheem",
                    meaning: "In the name of God, Most Gracious, Most Merciful"
                )

                fatihaVerse(
                    arabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
                    transliteration: "Al-hamdu lillaahi Rabbil-'aalameen",
                    meaning: "Praise be to God, Lord of the universe"
                )

                fatihaVerse(
                    arabic: "الرَّحْمَٰنِ الرَّحِيمِ",
                    transliteration: "Ar-Rahmaanir-Raheem",
                    meaning: "Most Gracious, Most Merciful"
                )

                fatihaVerse(
                    arabic: "مَالِكِ يَوْمِ الدِّينِ",
                    transliteration: "Maaliki Yawmid-Deen",
                    meaning: "Master of the Day of Judgment"
                )

                fatihaVerse(
                    arabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
                    transliteration: "Iyyaaka na'budu wa iyyaaka nasta'een",
                    meaning: "You alone we worship; You alone we ask for help"
                )

                fatihaVerse(
                    arabic: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ",
                    transliteration: "Ihdinas-Siraatal-Mustaqeem",
                    meaning: "Guide us in the straight path"
                )

                fatihaVerse(
                    arabic: "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ",
                    transliteration: "Siraatal-lazeena an'amta 'alayhim, ghayril-maghdoobi 'alayhim walad-daalleen",
                    meaning: "The path of those whom You blessed, not of those who incur wrath, nor the strayers"
                )
            }
        }
    }

    private func fatihaVerse(arabic: String, transliteration: String, meaning: String) -> some View {
        VStack(spacing: 10) {
            Text(arabic)
                .font(DS.Font.arabic(20))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(transliteration)
                .font(DS.Typography.quote)
                .foregroundStyle(Color.accentColor)
                .multilineTextAlignment(.center)

            Text(meaning)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Tashahhud Page

    private var tashahhudPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "hand.point.up")
                    .font(.system(size: 50))
                    .foregroundStyle(.teal)

                Text("Tashahhud")
                    .font(DS.Typography.titleLG)

                Text("Testimony of Faith")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            tutorialHighlight(
                icon: "info.circle",
                title: "When to Recite",
                text: "Recited while sitting at the end of the 2nd unit, and at the final unit of each prayer."
            )

            // First part
            tutorialCard {
                VStack(spacing: 16) {
                    Text("First Declaration")
                        .font(DS.Typography.titleSM)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        Text("أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ")
                            .font(DS.Font.arabic(24))

                        Text("Ash-hadu allaa ilaaha illallaah")
                            .font(DS.Typography.quote)
                            .foregroundStyle(Color.accentColor)

                        Text("I bear witness that there is no god except God")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
            }

            // Second part
            tutorialCard {
                VStack(spacing: 16) {
                    Text("Second Declaration")
                        .font(DS.Typography.titleSM)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        Text("وَحْدَهُ لَا شَرِيكَ لَهُ")
                            .font(DS.Font.arabic(24))

                        Text("Wahdahu laa shareeka lah")
                            .font(DS.Typography.quote)
                            .foregroundStyle(Color.accentColor)

                        Text("He alone is God; He has no partner")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
            }

            // Salaam
            tutorialCard {
                VStack(spacing: 16) {
                    Label("Ending the Prayer", systemImage: "hand.wave")
                        .font(DS.Typography.titleSM)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.teal)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Look right and say:")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(.secondary)
                                Text("Assalaamu Alaikum")
                                    .fontWeight(.medium)
                                Text("Peace be upon you")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left")
                                .foregroundStyle(.teal)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Look left and say:")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(.secondary)
                                Text("Assalaamu Alaikum")
                                    .fontWeight(.medium)
                                Text("Peace be upon you")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Prayer Units Page

    private var prayerUnitsPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "list.number")
                    .font(.system(size: 50))
                    .foregroundStyle(.indigo)

                Text("Prayer Units")
                    .font(DS.Typography.titleLG)

                Text("Rak'ah Structure")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Each prayer
            VStack(spacing: 12) {
                prayerStructureCard(
                    name: "Dawn",
                    arabic: "Fajr",
                    units: 2,
                    icon: "sunrise",
                    color: .orange,
                    structure: "2 units → Tashahhud → Salaam"
                )

                prayerStructureCard(
                    name: "Noon",
                    arabic: "Dhuhr",
                    units: 4,
                    icon: "sun.max",
                    color: .yellow,
                    structure: "2 units → Tashahhud → 2 units → Tashahhud → Salaam"
                )

                prayerStructureCard(
                    name: "Afternoon",
                    arabic: "Asr",
                    units: 4,
                    icon: "sun.haze",
                    color: .orange,
                    structure: "2 units → Tashahhud → 2 units → Tashahhud → Salaam"
                )

                prayerStructureCard(
                    name: "Sunset",
                    arabic: "Maghrib",
                    units: 3,
                    icon: "sunset",
                    color: .red,
                    structure: "2 units → Tashahhud → 1 unit → Tashahhud → Salaam"
                )

                prayerStructureCard(
                    name: "Night",
                    arabic: "Isha",
                    units: 4,
                    icon: "moon.stars",
                    color: .indigo,
                    structure: "2 units → Tashahhud → 2 units → Tashahhud → Salaam"
                )
            }

            // Note
            tutorialHighlight(
                icon: "lightbulb",
                title: "Remember",
                text: "The Tashahhud after unit 2 does NOT end with Salaam (except in Dawn prayer). Stand up for the remaining units."
            )
        }
    }

    private func prayerStructureCard(name: String, arabic: String, units: Int, icon: String, color: Color, structure: String) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(DS.Typography.titleMD)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(DS.Typography.titleSM)

                    Text("(\(arabic))")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(units) units")
                        .font(DS.Typography.label)
                        .foregroundStyle(color)
                }

                Text(structure)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Friday Page

    private var fridayPage: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Friday Prayer")
                    .font(DS.Typography.titleLG)

                Text("Jumu'ah")
                    .font(DS.Typography.titleSM)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            tutorialHighlight(
                icon: "calendar",
                title: "Special Prayer",
                text: "The Friday prayer replaces the Noon prayer on Fridays when praying in congregation."
            )

            tutorialCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Structure")
                        .font(DS.Typography.titleSM)

                    VStack(alignment: .leading, spacing: 12) {
                        fridayStep(number: 1, title: "First Sermon (Khutba)", description: "Begins with \"Al-Hamdu Lillah\" and \"Laa Ilaaha Illa Allah\"")

                        fridayStep(number: 2, title: "Congregation Repents", description: "People say \"Tooboo Ilallaah\" (Repent to God)")

                        fridayStep(number: 3, title: "Second Sermon", description: "Another short sermon with the same opening")

                        fridayStep(number: 4, title: "Call to Prayer (Adhan)", description: "Marks the start of the prayer")

                        fridayStep(number: 5, title: "Two Units of Prayer", description: "Led by the Imam; congregation follows")
                    }
                }
            }

            // Group prayer note
            tutorialCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Group Prayer", systemImage: "person.2")
                        .font(DS.Typography.titleSM)

                    Text("In congregation, only the Imam recites Al-Fatiha aloud. Others listen silently and follow the movements.")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("If you join late, complete your missed units after the Imam finishes.")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Congratulations
            tutorialCard {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(DS.Typography.titleLG)
                        .foregroundStyle(.green)

                    Text("After Prayer")
                        .font(DS.Typography.titleSM)

                    Text("Worshippers may shake hands, hug, and greet each other, customarily saying \"Congratulations!\"")
                        .font(DS.Typography.bodySM)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func fridayStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.label)

                Text(description)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    private func tutorialCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tutorialHighlight(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(DS.Typography.titleMD)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DS.Typography.bodySM)
                    .fontWeight(.semibold)

                Text(text)
                    .font(DS.Typography.bodySM)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Tutorial Page Enum

private enum TutorialPage: CaseIterable {
    case intro
    case ablution
    case direction
    case positions
    case fatiha
    case tashahhud
    case prayerUnits
    case friday

    var title: String {
        switch self {
        case .intro: return "Introduction"
        case .ablution: return "Ablution"
        case .direction: return "Direction"
        case .positions: return "Positions"
        case .fatiha: return "Al-Fatiha"
        case .tashahhud: return "Tashahhud"
        case .prayerUnits: return "Prayer Units"
        case .friday: return "Friday Prayer"
        }
    }
}

#Preview {
    Prayer_Element_PrayerTutorial()
}
