import SwiftUI
import Charts

private struct HistoryDestination: Identifiable {
    let chapterNumber: Int
    let verseNumber: Int?
    var id: String {
        if let verseNumber { return "\(chapterNumber):\(verseNumber)" }
        return "\(chapterNumber)"
    }
}

struct Quran_Content_ReadingHistory: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared

    @State private var showClearConfirmation = false
    @State private var presentedDestination: HistoryDestination?
    @State private var collapsedSections: Set<String> = []
    @State private var groupToDelete: String?
    @State private var actionFilter: ReadingAction?

    // Mono fonts
    private let mono = DS.Font.mono(10, weight: .regular)
    private let monoMed = DS.Font.mono(10, weight: .medium)
    private let monoSm = DS.Font.mono(9, weight: .regular)

    var body: some View {
        content
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !store.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Delete history", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Last hour", role: .destructive) {
                    let cutoff = Date().addingTimeInterval(-3600)
                    withAnimation { store.removeAll { $0.startedAt >= cutoff } }
                }
                Button("Last 24 hours", role: .destructive) {
                    let cutoff = Date().addingTimeInterval(-86400)
                    withAnimation { store.removeAll { $0.startedAt >= cutoff } }
                }
                Button("Last 7 days", role: .destructive) {
                    let cutoff = Date().addingTimeInterval(-7 * 86400)
                    withAnimation { store.removeAll { $0.startedAt >= cutoff } }
                }
                Button("All history", role: .destructive) {
                    withAnimation { store.clear() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Delete entries from \(groupToDelete ?? "")?",
                isPresented: .init(
                    get: { groupToDelete != nil },
                    set: { if !$0 { groupToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Period", role: .destructive) {
                    if let label = groupToDelete {
                        let calendar = Calendar.current
                        withAnimation {
                            store.removeAll { dayLabel(for: $0.updatedAt, calendar: calendar) == label }
                        }
                        groupToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { groupToDelete = nil }
            }
            .navigationDestination(for: Router.Destination.self) { destination in
                Router.shared.view(for: destination)
            }
            .sheet(item: $presentedDestination) { destination in
                NavigationStack {
                    Quran_Content_ChapterReader(
                        chapterNumber: destination.chapterNumber,
                        options: .init(scrollToVerseNumber: destination.verseNumber, action: .opened)
                    )
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if store.history.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Activity Yet")
                .font(DS.Typography.titleLG)
            Text("Your reading sessions will appear here.")
                .font(DS.Typography.bodySM)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - List

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                InsightsMiniCard()
                    .padding(.horizontal)
                    .padding(.vertical, DS.Spacing.md)

                filterChips
                    .padding(.horizontal)
                    .padding(.bottom, DS.Spacing.md)

                ForEach(groupedEntries, id: \.label) { group in
                    let isCollapsed = collapsedSections.contains(group.label)

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            if isCollapsed { collapsedSections.remove(group.label) }
                            else { collapsedSections.insert(group.label) }
                        }
                    } label: {
                        HStack {
                            Text(group.label)
                                .font(DS.Typography.eyebrow)
                                .tracking(2)
                                .foregroundStyle(.secondary)
                            Text("\(group.sessions.count)")
                                .font(DS.Typography.eyebrowSM)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { groupToDelete = group.label } label: {
                            Label("Delete \(group.label)", systemImage: "trash")
                        }
                    }

                    if !isCollapsed {
                        ForEach(group.sessions) { session in
                            sessionCard(session)
                                .padding(.horizontal)
                                .padding(.vertical, DS.Spacing.xs)
                        }
                    }
                }
            }
            .padding(.bottom, 200)
        }
    }

    // MARK: - Filter (sorted deterministically by raw value)

    private var filterChips: some View {
        let actionCounts = Dictionary(grouping: store.history, by: \.action)
        let actions = ReadingAction.allCases.compactMap { act -> (action: ReadingAction, count: Int)? in
            guard let count = actionCounts[act]?.count, count > 0 else { return nil }
            return (action: act, count: count)
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chipButton(label: "All", icon: nil, selected: actionFilter == nil) {
                    withAnimation(.easeOut(duration: 0.2)) { actionFilter = nil }
                }
                ForEach(actions, id: \.action) { item in
                    chipButton(label: item.action.rawValue, icon: item.action.icon, selected: actionFilter == item.action) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            actionFilter = actionFilter == item.action ? nil : item.action
                        }
                    }
                }
            }
        }
    }

    private func chipButton(label: String, icon: String?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.system(size: 9)) }
                Text(label).font(DS.Typography.eyebrowSM)
            }
            .foregroundStyle(selected ? .white : DS.Color.fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? Color.accentColor : Color.secondary.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Groups

    private struct DayGroup {
        let label: String
        let sessions: [QuranReadingSession]
    }

    private var filteredHistory: [QuranReadingSession] {
        guard let filter = actionFilter else { return store.history }
        return store.history.filter { $0.action == filter }
    }

    private var groupedEntries: [DayGroup] {
        let calendar = Calendar.current
        var groups: [DayGroup] = []
        var currentLabel = ""
        var current: [QuranReadingSession] = []

        for session in filteredHistory {
            let label = dayLabel(for: session.updatedAt, calendar: calendar)
            if label != currentLabel {
                if !current.isEmpty { groups.append(DayGroup(label: currentLabel, sessions: current)) }
                currentLabel = label
                current = [session]
            } else {
                current.append(session)
            }
        }
        if !current.isEmpty { groups.append(DayGroup(label: currentLabel, sessions: current)) }
        return groups
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInYesterday(date) { return "YESTERDAY" }
        let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if daysAgo < 7 { return date.formatted(.dateTime.weekday(.wide)).uppercased() }
        return date.formatted(.dateTime.month(.wide).day().year()).uppercased()
    }

    // MARK: - Session Card

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private func sessionCard(_ session: QuranReadingSession) -> some View {
        let timeText = Self.timeFormatter.string(from: session.startedAt)
        let durationSec = session.duration
        let durationText = durationSec >= 60 ? "\(Int(durationSec / 60))m" : nil
        let eventCount = session.events.count

        return Button {
            if session.chapterNumber > 0 {
                presentedDestination = HistoryDestination(
                    chapterNumber: session.chapterNumber,
                    verseNumber: session.verseNumber > 0 ? session.verseNumber : nil
                )
            }
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Action + subject
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(session.action.verb)
                        .font(DS.Typography.label)
                        .foregroundStyle(.accent)

                    if session.chapterNumber > 0 {
                        Text("Sura \(session.chapterNumber): \(session.chapterTitle)")
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Color.fg)
                            .lineLimit(1)
                    } else if let detail = session.events.first?.detail {
                        Text(detail)
                            .font(DS.Typography.label)
                            .foregroundStyle(DS.Color.fg)
                            .lineLimit(1)
                    }
                }

                // Metadata chips
                HStack(spacing: DS.Spacing.sm) {
                    metaChip(text: timeText, icon: nil)

                    if let durationText {
                        metaChip(text: durationText, icon: nil)
                    }

                    if !session.verseId.isEmpty {
                        metaChip(text: session.verseId, icon: nil)
                    }

                    if eventCount > 1 {
                        metaChip(text: "\(eventCount) steps", icon: nil)
                    }
                }

                // Condensed timeline (show first + last only for brevity)
                if eventCount > 1 {
                    let first = session.events.first!
                    let last = session.events.last!

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Divider()
                        timelineRow(event: first, isFirst: true)
                        if eventCount > 2 {
                            Text("\(eventCount - 2) more")
                                .font(monoSm)
                                .foregroundStyle(DS.Color.fgMuted.opacity(0.5))
                                .padding(.leading, 14)
                        }
                        timelineRow(event: last, isFirst: false)
                    }
                }
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(DS.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
        )
        .contextMenu {
            if session.chapterNumber > 0 {
                Button {
                    presentedDestination = HistoryDestination(
                        chapterNumber: session.chapterNumber,
                        verseNumber: session.verseNumber > 0 ? session.verseNumber : nil
                    )
                } label: {
                    Label("Open", systemImage: "book.closed")
                }
            }
            Button(role: .destructive) {
                withAnimation { store.remove(session) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func metaChip(text: String, icon: String?) -> some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon).font(.system(size: 8))
            }
            Text(text)
        }
        .font(monoSm)
        .foregroundStyle(DS.Color.fgMuted)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func timelineRow(event: ReadingEvent, isFirst: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(isFirst ? Color.accentColor : Color.accentColor.opacity(0.35))
                .frame(width: 5, height: 5)

            Text(event.detail)
                .font(monoSm)
                .foregroundStyle(DS.Color.fgMuted)
                .lineLimit(1)

            Spacer()

            Text(Self.timeFormatter.string(from: event.timestamp))
                .font(monoSm)
                .foregroundStyle(DS.Color.fgMuted.opacity(0.5))
        }
    }
}
