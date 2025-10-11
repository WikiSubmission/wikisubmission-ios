import Foundation
import Defaults
import UIKit
#if os(macOS)
import AppKit
#endif

extension Utilities.Bookmarks {
    
    /// Returns bookmarks stored locally in user defaults.
    static private func getLocalStore() -> [Types.Bookmarks.Bookmark] {
        return Defaults[.bookmarks]
    }
    
    /// Adds a bookmark to local storage
    static func addBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard !bookmarks.contains(where: { $0.key == bookmark.key }) else { return }
        bookmarks.append(bookmark)
        Defaults[.bookmarks] = bookmarks
    }
    
    /// Removes a bookmark from local storage
    static func removeBookmark(_ bookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        let initialCount = bookmarks.count
        bookmarks.removeAll(where: { $0.key == bookmark.key })
        guard bookmarks.count < initialCount else { return }
        Defaults[.bookmarks] = bookmarks
    }
    
    /// Edits a bookmark in local storage
    static func editBookmark(_ bookmark: Types.Bookmarks.Bookmark, newBookmark: Types.Bookmarks.Bookmark) async throws -> Void {
        var bookmarks = Defaults[.bookmarks]
        guard let index = bookmarks.firstIndex(where: { $0.key == bookmark.key }) else { return }
        bookmarks[index] = newBookmark
        Defaults[.bookmarks] = bookmarks
    }
    
    /// Deletes all bookmarks locally
    static func deleteAll() async throws {
        Defaults[.bookmarks] = []
    }
    
    /// Exports all bookmarks as a JSON file and presents a share sheet to share the file
    static func exportBookmarks() {
        // Get bookmarks from local storage
        let bookmarks = Defaults[.bookmarks]
        
        // Initialize JSON encoder with pretty printed format
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            // Encode bookmarks to JSON data
            let data = try encoder.encode(bookmarks)
            
            // Generate a filename with current date and time to ensure uniqueness
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let filename = "QuranBookmarks-\(dateString).json"
            
            // Create a temporary file URL in the system's temporary directory
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectory.appendingPathComponent(filename)
            
            // Write the encoded JSON data to the temporary file
            try data.write(to: tempFileURL, options: .atomic)
            
            // Present a share sheet (UIActivityViewController on iOS, NSSharingServicePicker on macOS) to share the JSON file URL
            #if os(iOS)
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true, completion: nil)
                }
            }
            #elseif os(macOS)
            DispatchQueue.main.async {
                let sharingPicker = NSSharingServicePicker(items: [tempFileURL])
                if let keyWindow = NSApplication.shared.keyWindow,
                   let contentView = keyWindow.contentView {
                    sharingPicker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
                }
            }
            #endif
            
        } catch {
            Utilities.System.GlobalAlertManager.shared.showAlert(title: "Error Exporting Bookmarks", subtitle: "\(error.localizedDescription)", systemImage: "square.and.arrow.up.trianglebadge.exclamationmark.fill", type: .error)
        }
    }
}
