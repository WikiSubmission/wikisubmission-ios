extension Utilities.System {
    @MainActor
    static func signInTasks() async {
        // Refresh bookmarks
        await AppEnvironment.shared.BookmarkManager.refresh()
    }
}
