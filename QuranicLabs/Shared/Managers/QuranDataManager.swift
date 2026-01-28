import SwiftUI
import SwiftData
import Defaults
import CodableCSV

extension Defaults.Keys {
    static let quran_data_initialized = Key<Bool>("quran_data_initialized", default: false)
    static let quran_data_last_cdn_check = Key<Date?>("quran_data_last_cdn_check", default: nil)
    static let quran_data_last_modified = Key<[String: Date]>("quran_data_last_modified", default: [:])
}

enum QuranDataFiles: String, CaseIterable {
    case ws_quran_chapters
    case ws_quran_index
    case ws_quran_text
    case ws_quran_subtitles
    case ws_quran_footnotes
    case ws_quran_word_by_word

    var bundlePath: URL {
        return Bundle.main.url(forResource: self.rawValue, withExtension: "csv")!
    }

    var cdnURL: URL {
        return URL(string: "https://cdn.wikisubmission.org/data/\(self.rawValue).csv")!
    }

    var displayName: String {
        return self.rawValue
            .replacingOccurrences(of: "ws_quran_", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }
    
    var displayDescription: String {
        switch self {
        case .ws_quran_index:
            return "data improvements"
        case .ws_quran_text, .ws_quran_chapters, .ws_quran_subtitles, .ws_quran_footnotes:
            return "translation improvements"
        case .ws_quran_word_by_word:
            return "word by word improvements"
        }
    }

    var initializationDisplayTitle: String {
        return "Setting things up"
    }

    var initializationDisplayText: String {
        switch self {
        case .ws_quran_chapters, .ws_quran_index, .ws_quran_text, .ws_quran_subtitles, .ws_quran_footnotes, .ws_quran_word_by_word:
            return "Loading data. This may take a moment..."
        }
    }
}

@MainActor
class QuranDataManager: ObservableObject {

    static var shared: QuranDataManager = QuranDataManager()
    
    static let backgroundUpdateCheckInterval: TimeInterval = 5 * 60 // 5 minutes
    private var backgroundUpdateCheckTimer: Timer?

    private let urlSession: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)

        if Defaults[.quran_data_initialized] {
            self.isReady = true
        }

        startBackgroundCheckTimer()
    }

    private func startBackgroundCheckTimer() {
        backgroundUpdateCheckTimer?.invalidate()
        backgroundUpdateCheckTimer = Timer.scheduledTimer(withTimeInterval: Self.backgroundUpdateCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForUpdates()
            }
        }
    }

    @Published var isReady = false
    @Published var progress: QuranDataManagerProgress = .init()
    @Published var updatesAvailable = false
    @Published var pendingUpdates: [QuranDataFiles] = []

    struct QuranDataManagerProgress {
        var title = "WikiSubmission"
        var displayText = ""

        mutating func update(text: String, title: String = "WikiSubmission") {
            self.displayText = text
            self.title = title
        }
    }
        
    func initializeFromBundle(modelContext: ModelContext) async {
        guard !Defaults[.quran_data_initialized] else {
            print("Quran data already initialized; skipping import.")
            return
        }

        for file in QuranDataFiles.allCases {
            print("Importing \(file.rawValue).csv...")
            progress.update(
                text: file.initializationDisplayText,
                title: file.initializationDisplayTitle
            )
            do {
                try await importFile(file: file, from: file.bundlePath, modelContext: modelContext)
                print("✓ Imported \(file.rawValue).csv from bundle")
            } catch {
                fatalError("Error importing \(file.rawValue): \(error)")
            }
        }
        isReady = true
        Defaults[.quran_data_initialized] = true
    }
    
    private func deleteExistingData(for file: QuranDataFiles, modelContext: ModelContext) async throws {
        switch file {
        case .ws_quran_chapters:
            try modelContext.delete(model: QuranChaptersSD.self)
        case .ws_quran_index:
            try modelContext.delete(model: QuranIndexSD.self)
        case .ws_quran_text:
            try modelContext.delete(model: QuranTextSD.self)
        case .ws_quran_subtitles:
            try modelContext.delete(model: QuranSubtitlesSD.self)
        case .ws_quran_footnotes:
            try modelContext.delete(model: QuranFootnotesSD.self)
        case .ws_quran_word_by_word:
            try modelContext.delete(model: QuranWordByWordSD.self)
        }
        try modelContext.save()
    }
    
    private func loadCSV<TempType: Decodable>(url: URL) async throws -> [TempType] {
        return try await Task.detached(priority: .userInitiated) {
            let csvData = try Data(contentsOf: url)
            
            var configuration = CSVDecoder.Configuration()
            configuration.delimiters = (field: ",", row: "\r\n")
            configuration.headerStrategy = .firstLine
            
            let decoder = CSVDecoder(configuration: configuration)
            return try decoder.decode([TempType].self, from: csvData)
        }.value
    }
    
    /// Clear all CDN-cached data and re-import from bundle
    /// Use this to ensure only bundled data is used in the app
    func clearCDNCacheAndReloadFromBundle(modelContext: ModelContext) async {
        // Show loading UI
        isReady = false
        progress.update(text: "Clearing CDN cache...", title: "Resetting")

        // Delete cached CDN files
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let quranCacheDir = cacheDir.appendingPathComponent("QuranData", isDirectory: true)

        do {
            if FileManager.default.fileExists(atPath: quranCacheDir.path) {
                try FileManager.default.removeItem(at: quranCacheDir)
                print("✓ Cleared QuranData cache directory")
            }
        } catch {
            print("⚠ Failed to clear cache directory: \(error)")
        }

        // Reset CDN tracking state
        Defaults[.quran_data_last_modified] = [:]
        Defaults[.quran_data_last_cdn_check] = nil
        pendingUpdates = []
        updatesAvailable = false

        // Force re-import from bundle
        Defaults[.quran_data_initialized] = false
        await initializeFromBundle(modelContext: modelContext)

        print("✓ Reloaded all data from bundle")
    }

    func checkForUpdates() async {
        var foundUpdates: [QuranDataFiles] = []
        let storedLastModified = Defaults[.quran_data_last_modified]

        for file in QuranDataFiles.allCases {
            if let _ = await checkFileForUpdate(file: file, currentLastModified: storedLastModified[file.rawValue]) {
                foundUpdates.append(file)
                print("Update available for \(file.displayName)")
            }
        }

        pendingUpdates = foundUpdates
        updatesAvailable = !foundUpdates.isEmpty
        Defaults[.quran_data_last_cdn_check] = Date()

        if foundUpdates.isEmpty {
            print("✓ Quran data is up to date")
        } else {
            print("\(foundUpdates.count) update(s) available")
        }
    }

    /// Minimum expected row counts for validation (protects against corrupted/empty CDN data)
    private func minimumRowCount(for file: QuranDataFiles) -> Int {
        switch file {
        case .ws_quran_chapters: return 1
        case .ws_quran_index: return 1
        case .ws_quran_text: return 1
        case .ws_quran_subtitles: return 1
        case .ws_quran_footnotes: return 1
        case .ws_quran_word_by_word: return 1
        }
    }

    /// Validate CDN data before importing - returns parsed row count if valid, nil if invalid
    private func validateCDNData(file: QuranDataFiles, from url: URL) async -> Int? {
        do {
            let rowCount: Int
            switch file {
            case .ws_quran_chapters:
                let rows: [QuranChaptersTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            case .ws_quran_index:
                let rows: [QuranIndexTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            case .ws_quran_text:
                let rows: [QuranTextTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            case .ws_quran_subtitles:
                let rows: [QuranSubtitlesTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            case .ws_quran_footnotes:
                let rows: [QuranFootnotesTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            case .ws_quran_word_by_word:
                let rows: [QuranWordByWordTemp] = try await loadCSV(url: url)
                rowCount = rows.count
            }

            let minRequired = minimumRowCount(for: file)
            if rowCount >= minRequired {
                return rowCount
            } else {
                print("⚠ Validation failed for \(file.displayName): got \(rowCount) rows, expected at least \(minRequired)")
                return nil
            }
        } catch {
            print("⚠ Validation failed for \(file.displayName): \(error)")
            return nil
        }
    }

    private func checkFileForUpdate(file: QuranDataFiles, currentLastModified: Date?) async -> Date? {
        guard let cdnLastModified = await getLastModifiedDate(for: file) else {
            return nil
        }
        // If we have no stored Last-Modified, or it changed, update is available
        if currentLastModified == nil || currentLastModified! < cdnLastModified {
            return cdnLastModified
        }
        return nil
    }

    private func getLastModifiedDate(for file: QuranDataFiles) async -> Date? {
        do {
            var request = URLRequest(url: file.cdnURL)
            request.httpMethod = "HEAD"
            let (_, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            if let lastModifiedString = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss z"
                return formatter.date(from: lastModifiedString)
            }
            return nil
        } catch {
            print("CDN check failed for \(file.displayName): \(error)")
            return nil
        }
    }

    func downloadUpdates(modelContext: ModelContext) async {
        guard !pendingUpdates.isEmpty else { return }

        // Show loading UI
        isReady = false
        progress.update(text: "Downloading updates...", title: "Updating")

        for (index, file) in pendingUpdates.enumerated() {
            progress.update(
                text: "Updating \(file.displayName)... (\(index + 1)/\(pendingUpdates.count))",
                title: "Updating"
            )

            do {
                // Download CSV from CDN
                let (data, response) = try await urlSession.data(from: file.cdnURL)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("⚠ Download failed for \(file.displayName): bad status")
                    continue
                }

                // Save to cache
                let cacheURL = getCacheURL(for: file)
                try data.write(to: cacheURL)

                // Validate CDN data before importing
                guard let rowCount = await validateCDNData(file: file, from: cacheURL) else {
                    print("⚠ Skipping \(file.displayName): validation failed, keeping existing data")
                    // Delete the invalid cached file
                    try? FileManager.default.removeItem(at: cacheURL)
                    continue
                }

                // Import from cached file (validation passed)
                try await importFile(file: file, from: cacheURL, modelContext: modelContext)

                // Store Last-Modified using HEAD request to ensure consistency with checkForUpdates()
                if let lastModified = await getLastModifiedDate(for: file) {
                    var lastModifiedDict = Defaults[.quran_data_last_modified]
                    lastModifiedDict[file.rawValue] = lastModified
                    Defaults[.quran_data_last_modified] = lastModifiedDict
                }

                print("✓ Updated \(file.displayName) from CDN (\(rowCount) rows)")

            } catch {
                print("⚠ Update failed for \(file.displayName): \(error)")
                // Continue with other files
            }
        }

        // Clear pending updates and complete
        pendingUpdates = []
        updatesAvailable = false
        isReady = true
    }

    /// Import a single file from a URL (bundle or CDN cache)
    private func importFile(file: QuranDataFiles, from url: URL, modelContext: ModelContext) async throws {
        try await deleteExistingData(for: file, modelContext: modelContext)

        switch file {
        case .ws_quran_chapters:
            let rows: [QuranChaptersTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranChaptersSD(
                    chapter_number: row.chapter_number, chapter_verses: row.chapter_verses,
                    revelation_order: row.revelation_order, title_english: row.title_english,
                    title_arabic: row.title_arabic, title_transliterated: row.title_transliterated,
                    title_turkish: row.title_turkish, title_french: row.title_french,
                    title_german: row.title_german, title_bahasa: row.title_bahasa,
                    title_persian: row.title_persian, title_tamil: row.title_tamil,
                    title_swedish: row.title_swedish, title_russian: row.title_russian,
                    title_bengali: row.title_bengali, title_urdu: row.title_urdu,
                    title_spanish: row.title_spanish
                )
                modelContext.insert(model)
            }

        case .ws_quran_index:
            let rows: [QuranIndexTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranIndexSD(
                    verse_index: row.verse_index, verse_id: row.verse_id,
                    chapter_number: row.chapter_number, verse_number: row.verse_number,
                    chapter_verses: row.chapter_verses, verse_id_arabic: row.verse_id_arabic
                )
                modelContext.insert(model)
            }

        case .ws_quran_text:
            let rows: [QuranTextTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranTextSD(
                    verse_index: row.verse_index, verse_id: row.verse_id, english: row.english, arabic: row.arabic, transliterated: row.transliterated, arabic_clean: row.arabic_clean, chapter_number: row.chapter_number, verse_number: row.verse_number, turkish: row.turkish, french: row.french, german: row.german, bahasa: row.bahasa, persian: row.persian, tamil: row.tamil, swedish: row.swedish, russian: row.russian, bengali: row.bengali, urdu: row.urdu, persian_new: row.persian_new, spanish: row.spanish
                )
                modelContext.insert(model)
            }

        case .ws_quran_subtitles:
            let rows: [QuranSubtitlesTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranSubtitlesSD(
                    verse_index: row.verse_index, verse_id: row.verse_id, english: row.english,
                    chapter_number: row.chapter_number, verse_number: row.verse_number,
                    turkish: row.turkish, french: row.french, german: row.german, bahasa: row.bahasa,
                    persian: row.persian, tamil: row.tamil, swedish: row.swedish, russian: row.russian,
                    bengali: row.bengali, spanish: row.spanish, urdu: row.urdu
                )
                modelContext.insert(model)
            }

        case .ws_quran_footnotes:
            let rows: [QuranFootnotesTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranFootnotesSD(
                    verse_index: row.verse_index, verse_id: row.verse_id, english: row.english,
                    chapter_number: row.chapter_number, verse_number: row.verse_number,
                    turkish: row.turkish, french: row.french, german: row.german, bahasa: row.bahasa,
                    persian: row.persian, tamil: row.tamil, swedish: row.swedish, russian: row.russian,
                    bengali: row.bengali, spanish: row.spanish, urdu: row.urdu
                )
                modelContext.insert(model)
            }

        case .ws_quran_word_by_word:
            let rows: [QuranWordByWordTemp] = try await loadCSV(url: url)
            for row in rows {
                let model = QuranWordByWordSD(
                    index: row.index, verse_index: row.verse_index, verse_id: row.verse_id,
                    word_index: row.word_index, root_word: row.root_word, arabic: row.arabic,
                    english: row.english, transliterated: row.transliterated, meanings: row.meanings,
                    chapter_number: row.chapter_number, verse_number: row.verse_number
                )
                modelContext.insert(model)
            }
        }

        try modelContext.save()
    }

    private func getCacheURL(for file: QuranDataFiles) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let quranCacheDir = cacheDir.appendingPathComponent("QuranData", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: quranCacheDir, withIntermediateDirectories: true)

        return quranCacheDir.appendingPathComponent("\(file.rawValue).csv")
    }
}

struct QuranChaptersTemp: Decodable {
    let chapter_number: Int
    let chapter_verses: Int
    let revelation_order: Int
    let title_english: String
    let title_arabic: String
    let title_transliterated: String
    let title_turkish: String
    let title_french: String
    let title_german: String
    let title_bahasa: String
    let title_persian: String
    let title_tamil: String
    let title_swedish: String
    let title_russian: String
    let title_bengali: String
    let title_urdu: String
    let title_spanish: String
}

struct QuranIndexTemp: Decodable {
    let verse_index: Int
    let verse_id: String
    let chapter_number: Int
    let verse_number: Int
    let chapter_verses: Int
    let verse_id_arabic: String
}

struct QuranTextTemp: Decodable {
    let verse_index: Int
    let verse_id: String
    let english: String
    let arabic: String
    let transliterated: String
    let arabic_clean: String
    let chapter_number: Int
    let verse_number: Int
    let turkish: String
    let french: String
    let german: String
    let bahasa: String
    let persian: String
    let tamil: String
    let swedish: String
    let russian: String
    let bengali: String
    let urdu: String
    let persian_new: String
    let spanish: String
}

struct QuranSubtitlesTemp: Decodable {
    let verse_index: Int
    let verse_id: String
    let english: String
    let chapter_number: Int
    let verse_number: Int
    let turkish: String
    let french: String
    let german: String
    let bahasa: String
    let persian: String
    let tamil: String
    let swedish: String
    let russian: String
    let bengali: String
    let spanish: String
    let urdu: String
}

struct QuranFootnotesTemp: Decodable {
    let verse_index: Int
    let verse_id: String
    let english: String
    let chapter_number: Int
    let verse_number: Int
    let turkish: String
    let french: String
    let german: String
    let bahasa: String
    let persian: String
    let tamil: String
    let swedish: String
    let russian: String
    let bengali: String
    let spanish: String
    let urdu: String
}

struct QuranWordByWordTemp: Decodable {
    let index: Int
    let verse_index: Int
    let verse_id: String
    let word_index: Int
    let root_word: String?
    let arabic: String
    let english: String
    let transliterated: String
    let meanings: String?
    let chapter_number: Int
    let verse_number: Int
}
