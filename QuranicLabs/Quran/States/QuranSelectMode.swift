import SwiftUI

@Observable
class QuranSelectMode {
    var canSelect: Bool = false
    var isActive: Bool = false
    var selection: [QuranUnified] = []

    func addSelection(_ item: QuranUnified) {
        if !selection.contains(item) {
            selection.append(item)
        }
    }

    func removeSelection(_ item: QuranUnified) {
        selection.removeAll { $0 == item }
    }

    func reset() {
        self.canSelect = false
        self.isActive = false
        self.selection.removeAll()
    }
}
