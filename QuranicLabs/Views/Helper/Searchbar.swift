import Foundation
import SwiftUI
import Combine

enum SearchbarTypingState {
    case idle
    case typing
    case doneTyping
}

enum SearchbarQueryState: Equatable {
    case idle
    case loading
    case done
    case error(Error)
    
    static func == (lhs: SearchbarQueryState, rhs: SearchbarQueryState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.done, .done):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

struct Searchbar<Element>: View where Element: Identifiable {
    @Binding var query: String
    @Binding var typingState: SearchbarTypingState
    @Binding var queryState: SearchbarQueryState
    @Binding var queryResults: [Element]
    
    var queryFunction: (String, @escaping (Result<[Element], Error>) -> Void) -> Void
    
    @FocusState var isFocused: Bool
    @StateObject var localQuery = QueryDebouncer()
    
    var placeholder: String
    var autoFocus = true
    var showClearSearchButton = true
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Image(systemName: typingState == .typing ? "ellipsis" : (queryState == .loading ? "hourglass" : "magnifyingglass"))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20, height: 20)
            }
            .frame(width: 20, height: 20) // fixed space for alignment
            .padding(.leading)
            
            
            TextField(placeholder, text: $localQuery.text)
                .font(.title2)
                .padding(.leading, 8)
                .padding(.vertical, 10)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onAppear {
                    if query.isEmpty { typingState = .idle }
                    if autoFocus { isFocused = true }
                }
                .onChange(of: localQuery.debouncedText) { _, newValue in
                    query = newValue
                    typingState = newValue.isEmpty ? .idle : .doneTyping
                    
                    if !newValue.isEmpty {
                        queryState = .loading
                        queryFunction(newValue) { result in
                            DispatchQueue.main.async {
                                withAnimation {
                                    switch result {
                                    case .success(let data):
                                        queryResults = data
                                        queryState = .done
                                    case .failure(let error):
                                        queryResults = []
                                        queryState = .error(error)
                                    }
                                }
                            }
                        }
                    } else {
                        queryResults = []
                        queryState = .idle
                    }
                }
                .onChange(of: localQuery.text) { _, newValue in
                    if !newValue.isEmpty {
                        typingState = .typing
                    }
                }
            
            if showClearSearchButton && !localQuery.text.isEmpty {
                Button {
                    isFocused = true
                    localQuery.text = ""
                    typingState = .idle
                    queryResults = []
                    queryState = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.secondary)
                        .padding(.trailing)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
        .animation(.easeInOut(duration: 0.2), value: localQuery.text.isEmpty)
    }
}

public final class QueryDebouncer: ObservableObject {
    @Published var text: String = ""
    @Published var debouncedText: String = ""
    private var bag = Set<AnyCancellable>()
    
    public init(dueTime: TimeInterval = 0.8) {
        $text
            .removeDuplicates()
            .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &bag)
    }
}

struct TypingIndicatorView: View {
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "ellipsis.circle.fill") // or "arrow.triangle.2.circlepath" / any SF icon
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.accentColor)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
    }
}

#Preview {
    QuranView()
}
