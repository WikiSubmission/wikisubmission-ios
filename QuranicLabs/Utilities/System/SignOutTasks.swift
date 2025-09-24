extension Utilities.System {
    @MainActor
    static func signOutTasks() async {
        // Reset bookmarks
        await AppEnvironment.shared.BookmarkManager.clearAll(onlyLocally: true)
    }
}
