import SwiftUI

/// A flow layout that wraps items to new lines when they exceed available width.
/// Properly handles RTL layout direction and spacing.
struct FlexStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    struct CacheData {
        var rows: [[LayoutSubviews.Element]] = []
        var rowHeights: [CGFloat] = []
    }

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        cache.rows = computeRows(subviews: subviews, containerWidth: containerWidth)
        cache.rowHeights = cache.rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }

        let totalHeight = cache.rowHeights.reduce(0, +) + max(0, CGFloat(cache.rows.count - 1)) * verticalSpacing
        return CGSize(width: containerWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var y = bounds.minY

        for (rowIndex, row) in cache.rows.enumerated() {
            let rowHeight = cache.rowHeights[rowIndex]
            var x = bounds.minX

            for (itemIndex, subview) in row.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))

                // Add spacing only between items, not after the last one
                if itemIndex < row.count - 1 {
                    x += size.width + horizontalSpacing
                }
            }

            y += rowHeight + verticalSpacing
        }
    }

    /// Groups subviews into rows based on available width
    private func computeRows(subviews: Subviews, containerWidth: CGFloat) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let itemWidth = subview.sizeThatFits(.unspecified).width
            let spacingNeeded = currentRow.isEmpty ? 0 : horizontalSpacing
            let projectedWidth = currentRowWidth + spacingNeeded + itemWidth

            if projectedWidth > containerWidth && !currentRow.isEmpty {
                // Start new row
                rows.append(currentRow)
                currentRow = [subview]
                currentRowWidth = itemWidth
            } else {
                // Add to current row
                currentRow.append(subview)
                currentRowWidth = projectedWidth
            }
        }

        // Don't forget the last row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
