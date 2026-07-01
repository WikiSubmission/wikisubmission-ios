import Defaults
import Foundation

struct Migrations {
    private static let migrationsKey = "completed_migrations"

    static func runAll() async {
        await v3_12()
        await v3_20_reciter()
    }

    // MARK: - v3.12: Bookmark Migration

    static func v3_12() async {
        let migrationId = "v3_12_bookmarks"
        guard !hasMigrationRun(migrationId) else { return }

        await MainActor.run {
            BookmarkManager.migrateFromLegacy()
        }

        markMigrationComplete(migrationId)
    }

    // MARK: - v3.20: Onyx → Callum reciter

    /// Callum replaces Onyx as the default English recitation. Move anyone still
    /// on Onyx over to Callum, while leaving deliberately-chosen Arabic reciters
    /// (Mishary, Basit, Minshawi) untouched.
    static func v3_20_reciter() async {
        let migrationId = "v3_20_onyx_to_callum"
        guard !hasMigrationRun(migrationId) else { return }

        await MainActor.run {
            if Defaults[.quran_reciter] == .onyx {
                Defaults[.quran_reciter] = .callum
            }
        }

        markMigrationComplete(migrationId)
    }

    // MARK: - Migration Tracking

    private static func hasMigrationRun(_ id: String) -> Bool {
        let completed = UserDefaults.standard.stringArray(forKey: migrationsKey) ?? []
        return completed.contains(id)
    }

    private static func markMigrationComplete(_ id: String) {
        var completed = UserDefaults.standard.stringArray(forKey: migrationsKey) ?? []
        if !completed.contains(id) {
            completed.append(id)
            UserDefaults.standard.set(completed, forKey: migrationsKey)
        }
    }
}
