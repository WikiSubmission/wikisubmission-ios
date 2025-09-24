import SwiftUI

extension Utilities.System {
    
    static func highlightQuery(_ source: String, query: String, highlightColor: Color = .red) -> Text {
        guard !source.isEmpty && !query.isEmpty else { return Text(source) }
        
        guard query.count > 2 else { return Text(source) }
        
        let queries = query.components(separatedBy: " ").filter { !$0.isEmpty }
        var attributed = AttributedString(source)
        
        for q in queries {
            let lowerSource = source.lowercased()
            let lowerQuery = q.lowercased()
            var searchStart = lowerSource.startIndex
            
            while let range = lowerSource[searchStart...].range(of: lowerQuery) {
                let nsRange = NSRange(range, in: source)
                if let attrRange = Range(nsRange, in: attributed) {
                    attributed[attrRange].foregroundColor = highlightColor
                }
                searchStart = range.upperBound
            }
        }
        
        return Text(attributed)
    }
}
