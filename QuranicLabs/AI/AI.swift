import SwiftUI
import Foundation

struct AIChat: View {
    @StateObject private var viewModel = AIChatViewModel()
    @ObservedObject private var networkManager = NetworkManager.shared
    @State private var showHistory = false
    @State private var showConversation = false
    private let bottomAnchorID = "main-ai-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                DS.Color.bg.ignoresSafeArea()

                AIEmptyState(
                    onSuggestionTap: { suggestion in
                        showConversation = true
                        Task {
                            await viewModel.submit(suggestion)
                        }
                    }
                )

                Color.clear
                    .frame(height: 1)
                    .id(bottomAnchorID)
            }
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                AIChatHistorySheet(viewModel: viewModel, onResume: {
                    showConversation = true
                })
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    AIMainComposer(
                        viewModel: viewModel,
                        hasInternet: networkManager.hasInternet,
                        onFocus: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                                }
                            }
                        },
                        onSend: {
                            showConversation = true
                        }
                    )

                    if AudioManager.shared.currentTrack != nil {
                        Color.clear.frame(height: 72)
                    }
                }
            }
            .navigationDestination(isPresented: $showConversation) {
                AIChatConversation(viewModel: viewModel)
                    .onDisappear {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            }
            .task {
                networkManager.checkConnectivity()
            }
        }
    }
}

// MARK: - Main Composer (for empty state)

private struct AIMainComposer: View {
    @ObservedObject var viewModel: AIChatViewModel
    let hasInternet: Bool
    let onFocus: () -> Void
    let onSend: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
            TextField("Ask anything…", text: $viewModel.input, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.fg)
                .lineLimit(1...5)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.send)
                .focused($focused)
                .onChange(of: focused) { _, isFocused in
                    if isFocused {
                        onFocus()
                    }
                }
                .onSubmit {
                    if viewModel.canSend && hasInternet {
                        focused = false
                        onSend()
                        Task {
                            await viewModel.submitCurrentInput()
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(DS.Color.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(DS.Color.rule.opacity(0.5), lineWidth: 1)
                )

            Button {
                focused = false
                onSend()
                Task {
                    await viewModel.submitCurrentInput()
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.canSend && hasInternet ? Color.accentColor : DS.Color.rule)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSend || !hasInternet)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.sm)
    }
}

// MARK: - Conversation View (pushed)

struct AIChatConversation: View {
    @ObservedObject var viewModel: AIChatViewModel
    @ObservedObject private var networkManager = NetworkManager.shared
    @FocusState private var inputFocused: Bool
    @State private var presentedReference: AIReferenceDestination?
    private let bottomAnchorID = "conversation-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                DS.Color.bg.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: DS.Spacing.lg) {
                        ForEach(viewModel.messages) { message in
                            AIMessageRow(
                                message: message,
                                onRetry: {
                                    Task {
                                        await viewModel.retry(message.id)
                                    }
                                },
                                onReferenceTap: { ref in openReference(ref) }
                            )
                            .id(message.id)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorID)
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded { inputFocused = false }
                )
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            viewModel.clear()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    AIComposer(
                        input: $viewModel.input,
                        isSending: viewModel.isSending,
                        canSend: viewModel.canSend && networkManager.hasInternet,
                        inputFocused: $inputFocused,
                        onSend: {
                            inputFocused = false
                            Task {
                                await viewModel.submitCurrentInput()
                            }
                        }
                    )

                    if AudioManager.shared.currentTrack != nil {
                        Color.clear.frame(height: 72)
                    }
                }
            }
            .overlay(alignment: .top) {
                if !networkManager.hasInternet {
                    AIStatusBanner(text: "Offline. Reconnect to continue chatting.")
                        .padding(.top, DS.Spacing.sm)
                }
            }
            .onChange(of: viewModel.messages) { _, messages in
                guard let lastID = messages.last?.id else { return }
                if messages.last?.isPending == true {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(lastID, anchor: .top)
                    }
                }
            }
            .onChange(of: inputFocused) { _, focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                        }
                    }
                }
            }
            .task {
                if let lastID = viewModel.messages.last?.id {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                }
            }
            .onDisappear {
                inputFocused = false
                if !viewModel.messages.isEmpty {
                    viewModel.storage.archiveCurrent()
                    viewModel.resetForNewSession()
                }
            }
            .sheet(item: $presentedReference) { destination in
                NavigationStack {
                    Quran_Content_ChapterReader(
                        chapterNumber: destination.chapterNumber,
                        options: .init(scrollToVerseNumber: destination.verseNumber)
                    )
                }
            }
        }
    }

    private func openReference(_ reference: String) {
        let components = reference.split(separator: ":")
        guard components.count == 2,
              let chapterNumber = Int(components[0]),
              let versePart = components[1].split(separator: "-").first,
              let verseNumber = Int(versePart) else { return }

        inputFocused = false
        presentedReference = AIReferenceDestination(
            chapterNumber: chapterNumber,
            verseNumber: verseNumber
        )
    }
}

private struct AIReferenceDestination: Identifiable {
    let chapterNumber: Int
    let verseNumber: Int

    var id: String { "\(chapterNumber):\(verseNumber)" }
}

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var input = ""
    @Published private(set) var messages: [AIChatMessage] = []
    @Published private(set) var isSending = false
    @Published private(set) var isResumedSession = false

    private let service: AIChatService
    private var conversationID: String?
    private var shouldReturnToConversation = false
    let storage = AIChatStorage()

    init(service: AIChatService = AIChatService()) {
        self.service = service
        // Archive any leftover current session, then start fresh
        storage.archiveCurrent()
        storage.clear()
    }

    var canSend: Bool {
        trimmedInput.count >= 2 && trimmedInput.count <= 500 && !isSending
    }

    func submitCurrentInput() async {
        let question = trimmedInput
        guard question.count >= 2 else { return }

        input = ""
        await submit(question)
    }

    func submit(_ question: String) async {
        let trimmed = Self.clean(question)
        guard trimmed.count >= 2, !isSending else { return }

        if conversationID == nil {
            conversationID = Self.newConversationID()
        }

        isSending = true

        let messageID = UUID()
        messages.append(.init(id: messageID, question: trimmed, state: .pending))
        persist()

        do {
            let reply = try await service.send(question: trimmed, conversationID: conversationID)
            updateMessage(id: messageID) { message in
                message.state = .answered(text: reply.answer, sources: reply.sources)
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
            updateMessage(id: messageID) { entry in
                entry.state = .failed(message)
            }
        }

        isSending = false
        persist()
    }

    func retry(_ messageID: UUID) async {
        guard let message = messages.first(where: { $0.id == messageID }) else { return }

        updateMessage(id: messageID) { entry in
            entry.state = .pending
        }

        isSending = true

        do {
            let reply = try await service.send(question: message.question, conversationID: conversationID)
            updateMessage(id: messageID) { entry in
                entry.state = .answered(text: reply.answer, sources: reply.sources)
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
            updateMessage(id: messageID) { entry in
                entry.state = .failed(message)
            }
        }

        isSending = false
        persist()
    }

    func clear() {
        // Archive current session before clearing
        storage.archiveCurrent()
        input = ""
        messages = []
        conversationID = nil
        isResumedSession = false
        storage.clear()
    }
    
    func resetForNewSession() {
        input = ""
        messages = []
        conversationID = nil
        isResumedSession = false
    }

    func resume(_ session: AIChatSession) {
        // Archive current if any
        if !messages.isEmpty {
            storage.archiveCurrent()
        }
        conversationID = session.conversationID
        messages = session.messages
        input = ""
        isResumedSession = true
        persist()
    }

    func markConversationReturnPending() {
        shouldReturnToConversation = true
    }

    func consumePendingConversationReturn() -> Bool {
        let pending = shouldReturnToConversation
        shouldReturnToConversation = false
        return pending
    }

    private var trimmedInput: String {
        Self.clean(input)
    }

    private func updateMessage(id: UUID, _ update: (inout AIChatMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        var message = messages[index]
        update(&message)
        messages[index] = message
    }

    private func persist() {
        storage.save(
            AIChatSession(
                conversationID: conversationID,
                messages: messages
            )
        )
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(500)
            .description
    }

    private static func newConversationID() -> String {
        String(UUID().uuidString.prefix(8)).lowercased()
    }
}

struct AIChatMessage: Identifiable, Equatable {
    let id: UUID
    let question: String
    var state: State

    enum State: Equatable {
        case pending
        case answered(text: String, sources: [String])
        case failed(String)
    }

    var isPending: Bool {
        if case .pending = state {
            return true
        }
        return false
    }
}

extension AIChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case state
    }

    enum StateCodingKeys: String, CodingKey {
        case kind
        case text
        case sources
        case error
    }

    enum StateKind: String, Codable {
        case pending
        case answered
        case failed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        question = try container.decode(String.self, forKey: .question)

        let stateContainer = try container.nestedContainer(keyedBy: StateCodingKeys.self, forKey: .state)
        switch try stateContainer.decode(StateKind.self, forKey: .kind) {
        case .pending:
            state = .pending
        case .answered:
            state = .answered(
                text: try stateContainer.decode(String.self, forKey: .text),
                sources: try stateContainer.decode([String].self, forKey: .sources)
            )
        case .failed:
            state = .failed(try stateContainer.decode(String.self, forKey: .error))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(question, forKey: .question)

        var stateContainer = container.nestedContainer(keyedBy: StateCodingKeys.self, forKey: .state)
        switch state {
        case .pending:
            try stateContainer.encode(StateKind.pending, forKey: .kind)
        case .answered(let text, let sources):
            try stateContainer.encode(StateKind.answered, forKey: .kind)
            try stateContainer.encode(text, forKey: .text)
            try stateContainer.encode(sources, forKey: .sources)
        case .failed(let error):
            try stateContainer.encode(StateKind.failed, forKey: .kind)
            try stateContainer.encode(error, forKey: .error)
        }
    }
}

private struct AIEmptyState: View {
    let onSuggestionTap: (String) -> Void

    private let suggestions = [
        "What is the significance of 19?",
        "What does the Quran say about prayer?",
        "Summarize the idea of submission to God.",
        "Explain 2:255 in simple terms."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    VStack(spacing: DS.Spacing.sm) {
                        Text("Ask anything.")
                            .font(DS.Typography.titleLG)
                            .foregroundStyle(DS.Color.fg)

                        Text("Early Preview")
                            .font(DS.Typography.eyebrowSM)
                            .tracking(1.3)
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            )

                        Text("Ask about Submission, scripture, verse references, or the mathematical miracle of 19.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Color.fgMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }
                }
                .padding(.top, DS.Spacing.section)

                VStack(spacing: DS.Spacing.sm) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                onSuggestionTap(suggestion)
                            }
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.accentColor)

                                Text(suggestion)
                                    .font(DS.Typography.bodySM)
                                    .foregroundStyle(DS.Color.fg)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.md)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(DS.Color.surface)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(DS.Color.rule.opacity(0.8), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 520)
                .padding(.bottom, 80)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.section)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct AIMessageRow: View {
    let message: AIChatMessage
    let onRetry: () -> Void
    let onReferenceTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Spacer(minLength: 44)

                Text(message.question)
                    .font(DS.Typography.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.accentColor)
                    )
                    .frame(maxWidth: 460, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                switch message.state {
                case .pending:
                    AITypingIndicator()
                        .padding(.vertical, DS.Spacing.xs)

                case .failed(let error):
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text(error)
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Color.destructive)
                            .textSelection(.enabled)

                        Button("Try again") {
                            onRetry()
                        }
                        .font(DS.Typography.label)
                        .foregroundStyle(Color.accentColor)
                    }

                case .answered(let text, let sources):
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        AIAnswerText(text: text)

                        if !sources.isEmpty {
                            AISourcesRow(sources: sources, onTap: onReferenceTap)
                        }
                    }
                }
            }
        }
    }
}

private struct AIAnswerText: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> SelfSizingTextView {
        let tv = SelfSizingTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .vertical)
        return tv
    }

    func updateUIView(_ tv: SelfSizingTextView, context: Context) {
        tv.attributedText = formatted
        tv.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView tv: SelfSizingTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let size = tv.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    private var formatted: NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: .newlines)

        let bodyFont = UIFont(name: "SourceSerif4-Regular", size: 15) ?? .systemFont(ofSize: 15)
        let headingFont = UIFont(name: "CormorantGaramond-Medium", size: 18) ?? .boldSystemFont(ofSize: 18)
        let textColor = UIColor.label
        let accentColor = UIColor(Color.accentColor)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        var previousWasEmpty = false

        for (i, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                if !previousWasEmpty && i > 0 {
                    result.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
                }
                previousWasEmpty = true
                continue
            }
            previousWasEmpty = false

            if result.length > 0 {
                result.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
            }

            // Heading
            if line.hasPrefix("#") {
                let cleaned = line.replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
                result.append(NSAttributedString(string: cleaned, attributes: [
                    .font: headingFont,
                    .foregroundColor: textColor
                ]))
                continue
            }

            // Bullet
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                let content = String(line.dropFirst(2))
                result.append(NSAttributedString(string: "•  ", attributes: [
                    .font: bodyFont,
                    .foregroundColor: accentColor
                ]))
                result.append(parseMarkdown(content, baseAttrs: bodyAttrs))
                continue
            }

            // Numbered
            let pieces = line.split(separator: ".", maxSplits: 1).map(String.init)
            if pieces.count == 2,
               let number = Int(pieces[0].trimmingCharacters(in: .whitespaces)) {
                result.append(NSAttributedString(string: "\(number).  ", attributes: [
                    .font: bodyFont,
                    .foregroundColor: accentColor
                ]))
                result.append(parseMarkdown(pieces[1].trimmingCharacters(in: .whitespaces), baseAttrs: bodyAttrs))
                continue
            }

            // Body
            result.append(parseMarkdown(line, baseAttrs: bodyAttrs))
        }

        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        return result
    }

    private func parseMarkdown(_ text: String, baseAttrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
        // Try to parse markdown for bold/italic
        if let data = text.data(using: .utf8),
           let parsed = try? NSAttributedString(
            markdown: data,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
           ) {
            let mutable = NSMutableAttributedString(attributedString: parsed)
            // Overlay base font/color but preserve traits (bold/italic)
            mutable.enumerateAttributes(in: NSRange(location: 0, length: mutable.length)) { attrs, range, _ in
                if let existingFont = attrs[.font] as? UIFont {
                    let traits = existingFont.fontDescriptor.symbolicTraits
                    var font = baseAttrs[.font] as! UIFont
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        font = UIFont(descriptor: descriptor, size: font.pointSize)
                    }
                    mutable.addAttribute(.font, value: font, range: range)
                } else {
                    mutable.addAttributes(baseAttrs, range: range)
                }
                if attrs[.foregroundColor] == nil {
                    mutable.addAttribute(.foregroundColor, value: baseAttrs[.foregroundColor]!, range: range)
                }
            }
            return mutable
        }
        return NSAttributedString(string: text, attributes: baseAttrs)
    }
}

private class SelfSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let width = frame.width > 0 ? frame.width : UIScreen.main.bounds.width - 64
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

private struct AIChatHistorySheet: View {
    @ObservedObject var viewModel: AIChatViewModel
    var onResume: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [AIChatSession] = []
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Past Sessions")
                            .font(DS.Typography.titleLG)
                        Text("Your conversations will be saved here.")
                            .font(DS.Typography.bodySM)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(sessions) { session in
                            Button {
                                viewModel.resume(session)
                                dismiss()
                                onResume?()
                            } label: {
                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text(session.title)
                                        .font(DS.Typography.label)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)

                                    HStack {
                                        Text("\(session.messages.count) messages")
                                            .font(DS.Typography.eyebrowSM)
                                            .foregroundStyle(.secondary)

                                        Spacer()

                                        Text(session.savedAt.relativeCompactAI())
                                            .font(DS.Typography.eyebrowSM)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, DS.Spacing.xs)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.storage.deleteSession(session)
                                    sessions = viewModel.storage.loadHistory()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if !sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Clear all chat history?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    viewModel.storage.clearHistory()
                    sessions = []
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onAppear {
            sessions = viewModel.storage.loadHistory()
        }
    }
}

private extension Date {
    func relativeCompactAI() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 {
            let h = Int(interval / 3600)
            return "\(h)h ago"
        }
        let d = Int(interval / 86400)
        return "\(d)d ago"
    }
}

private struct AISourcesRow: View {
    let sources: [String]
    let onTap: (String) -> Void

    private static func isValidVerse(_ source: String) -> Bool {
        let parts = source.split(separator: ":")
        guard parts.count == 2,
              let chapter = Int(parts[0]),
              chapter >= 1, chapter <= 114 else { return false }
        let versePart = parts[1].split(separator: "-").first
        guard let versePart, Int(versePart) != nil else { return false }
        return true
    }

    private var validSources: [String] {
        sources.filter { Self.isValidVerse($0) }
    }

    private var extraCount: Int {
        sources.count - validSources.count
    }

    var body: some View {
        if validSources.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Sources")
                    .font(DS.Typography.eyebrowSM)
                    .tracking(1.4)
                    .foregroundStyle(DS.Color.fgMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(validSources, id: \.self) { source in
                            Button {
                                onTap(source)
                            } label: {
                                Text(source)
                                    .font(DS.Typography.eyebrow)
                                    .foregroundStyle(Color.accentColor)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, DS.Spacing.md)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if extraCount > 0 {
                            Text("+ \(extraCount) more")
                                .font(DS.Typography.eyebrowSM)
                                .foregroundStyle(DS.Color.fgMuted)
                                .padding(.horizontal, DS.Spacing.sm)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        )
    }
}

private struct AIComposer: View {
    @Binding var input: String

    let isSending: Bool
    let canSend: Bool
    let inputFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
            TextField("Ask anything…", text: $input, axis: .vertical)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.fg)
                .lineLimit(1...5)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.send)
                .focused(inputFocused)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(DS.Color.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(DS.Color.rule.opacity(0.5), lineWidth: 1)
                )

            Button {
                onSend()
            } label: {
                Image(systemName: isSending ? "stop.fill" : "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(canSend || isSending ? Color.accentColor : DS.Color.rule)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend && !isSending)
            .accessibilityLabel(isSending ? "Stop" : "Send")
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.sm)
    }
}

private struct AITypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(DS.Color.fgMuted.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1 : 0.7)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever()
                            .delay(Double(index) * 0.12),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct AIChatSession: Codable, Identifiable {
    var id: String { conversationID ?? UUID().uuidString }
    let conversationID: String?
    let messages: [AIChatMessage]
    let savedAt: Date
    let title: String

    init(conversationID: String?, messages: [AIChatMessage]) {
        self.conversationID = conversationID
        self.messages = messages
        self.savedAt = Date()
        self.title = messages.first?.question ?? "Untitled"
    }
}

struct AIChatStorage {
    private let currentKey = "ai_chat_snapshot"
    private let historyKey = "ai_chat_history"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxSessions = 30

    func save(_ session: AIChatSession) {
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: currentKey)
    }

    func load() -> AIChatSession? {
        guard let data = defaults.data(forKey: currentKey) else { return nil }
        return try? decoder.decode(AIChatSession.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: currentKey)
    }

    // MARK: - History

    func archiveCurrent() {
        guard let current = load(), !current.messages.isEmpty else { return }
        // Only archive if there's at least one answered message
        let hasAnswer = current.messages.contains { msg in
            if case .answered = msg.state { return true }
            return false
        }
        guard hasAnswer else { return }

        var history = loadHistory()
        // Don't duplicate same conversation
        history.removeAll { $0.conversationID == current.conversationID }
        history.insert(current, at: 0)
        if history.count > maxSessions {
            history = Array(history.prefix(maxSessions))
        }
        saveHistory(history)
    }

    func loadHistory() -> [AIChatSession] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? decoder.decode([AIChatSession].self, from: data)) ?? []
    }

    func saveHistory(_ sessions: [AIChatSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        defaults.set(data, forKey: historyKey)
    }

    func deleteSession(_ session: AIChatSession) {
        var history = loadHistory()
        history.removeAll { $0.conversationID == session.conversationID }
        saveHistory(history)
    }

    func clearHistory() {
        defaults.removeObject(forKey: historyKey)
    }
}

private struct AIStatusBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.Typography.eyebrowSM)
            .foregroundStyle(DS.Color.fg)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(DS.Color.rule.opacity(0.9), lineWidth: 1)
            }
    }
}

private struct AIBlock: Identifiable {
    let id: Int
    let rawText: String
    let kind: Kind

    enum Kind {
        case spacer
        case heading
        case body
        case bullet
        case numbered(Int)
    }

    var attributed: AttributedString {
        if let parsed = try? AttributedString(markdown: rawText) {
            return parsed
        }
        return AttributedString(rawText)
    }
}
