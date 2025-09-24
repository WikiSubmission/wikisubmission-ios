import SwiftUI
import SheetKit

struct BetterPicker<T, Content>: View
where T: CaseIterable & Hashable, Content: View {
    
    @Binding var selection: T
    
    let previewLabel: String
    let previewIcon: String
    let rowContent: (T) -> Content
    
    /// Which cases to show (default = all)
    var allowedValues: [T]
    
    @State private var showSheet = false
    
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
        Button {
            SheetKit().presentWithEnvironment {
                NavigationStack {
                    List {
                        ForEach(allowedValues, id: \.self) { i in
                            Button {
                                selection = i
                                let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
                                hapticFeedback.impactOccurred()
                                SheetKit().dismiss()
                            } label: {
                                HStack {
                                    rowContent(i)
                                    Spacer()
                                    if i == selection {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .contentShape(Rectangle()) // entire row tappable
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .navigationTitle(previewLabel)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        } label: {
            HStack {
                Label(previewLabel, systemImage: previewIcon)
                Spacer()
                rowContent(selection)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
