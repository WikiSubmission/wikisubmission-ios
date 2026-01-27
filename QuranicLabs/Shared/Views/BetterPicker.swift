import SwiftUI
import UIKit

struct BetterPicker<T, Content>: View
where T: CaseIterable & Hashable, Content: View {

    @Binding var selection: T

    let previewLabel: String
    let previewIcon: String
    let rowContent: (T) -> Content

    /// Which cases to show (default = all)
    var allowedValues: [T]

    init(
        selection: Binding<T>,
        previewLabel: String,
        previewIcon: String,
        allowedValues: [T]? = nil,
        @ViewBuilder rowContent: @escaping (T) -> Content
    ) {
        self._selection = selection
        self.previewLabel = previewLabel
        self.previewIcon = previewIcon
        self.allowedValues = allowedValues ?? Array(T.allCases)
        self.rowContent = rowContent
    }

    var body: some View {
        NavigationLink {
            BetterPickerContent(
                selection: $selection,
                previewLabel: previewLabel,
                allowedValues: allowedValues,
                rowContent: rowContent
            )
        } label: {
            HStack {
                Label(previewLabel, systemImage: previewIcon)
                Spacer()
                rowContent(selection)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BetterPickerContent<T, Content>: View
where T: CaseIterable & Hashable, Content: View {

    @Binding var selection: T
    @Environment(\.dismiss) private var dismiss

    let previewLabel: String
    let allowedValues: [T]
    let rowContent: (T) -> Content

    var body: some View {
        List {
            ForEach(allowedValues, id: \.self) { i in
                Button {
                    selection = i
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                } label: {
                    HStack {
                        rowContent(i)
                        Spacer()
                        if i == selection {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(previewLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}
