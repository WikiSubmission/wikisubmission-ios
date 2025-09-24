import SwiftUI

struct ConditionalHighlight: View {
    let text: String
    var query: String = ""
    
    var body: some View {
        if query.count > 0 {
            Utilities.System.highlightQuery(text, query: query)
        } else {
            Text(text)
        }
    }
}
