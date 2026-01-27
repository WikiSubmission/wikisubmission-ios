import SwiftUI
import Defaults

struct QuranQuery {
    var query: String = ""
    var rawInput: String = ""

    mutating func reset() {
        query = ""
        rawInput = ""
    }

    mutating func commitQuery() {
        query = rawInput
    }

    func updateHistory() {
        var history = Defaults[.quran_search_history]
        history.removeAll { $0 == query }
        history.insert(query, at: 0)
        if history.count > 20 {
            history = Array(history.prefix(20))
        }
        Defaults[.quran_search_history] = history
    }

    func clearHistory() {
        Defaults[.quran_search_history] = []
    }
}
