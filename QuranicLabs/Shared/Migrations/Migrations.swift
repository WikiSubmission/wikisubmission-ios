import Defaults
import Foundation

struct Migrations {
    private static let migrationsKey = "completed_migrations"

    static func runAll() async {
        await v3_12()
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
