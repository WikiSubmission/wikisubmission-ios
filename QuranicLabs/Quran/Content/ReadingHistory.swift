import SwiftUI
import Charts

private struct HistoryDestination: Identifiable {
    let chapterNumber: Int
    let verseNumber: Int?

    var id: String {
        if let verseNumber {
            return "\(chapterNumber):\(verseNumber)"
        }
        return "\(chapterNumber)"
    }
}

struct Quran_Content_ReadingHistory: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared

    @State private var showClearConfirmation = false
    @State private var presentedDestination: HistoryDestination?

    var body: some View {
        content
            .navigationTitle("Reading History")
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
            .confirmationDialog("Clear all reading history?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    store.clear()
                }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(for: Router.Destination.self) { destination in
                Router.shared.view(for: destination)
            }
            .sheet(item: $presentedDestination) { destination in
                NavigationStack {
                    Quran_Content_ChapterReader(
                        chapterNumber: destination.chapterNumber,
                        options: .init(scrollToVerseNumber: destination.verseNumber)
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
            Text("No Reading History")
                .font(DS.Typography.titleLG)
            Text("Your reading sessions will appear here as you read.")
                .font(DS.Typography.bodySM)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                InsightsMiniCard()
                    .padding(.horizontal)
                    .padding(.vertical, DS.Spacing.md)

                ForEach(groupedEntries, id: \.label) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            historyRow(entry)
                            Divider().padding(.leading)
                        }
                    } header: {
                        Text(group.label)
                            .font(DS.Typography.eyebrow)
                            .tracking(2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.bottom, 200)
        }
    }

    // MARK: - Grouped Entries

    private struct HistoryGroup {
        let label: String
        let entries: [QuranReadingHistoryEntry]
    }

    private var groupedEntries: [HistoryGroup] {
        let calendar = Calendar.current
        var groups: [HistoryGroup] = []
        var currentLabel = ""
        var currentEntries: [QuranReadingHistoryEntry] = []

        for entry in store.history {
            let label = dayLabel(for: entry.updatedAt, calendar: calendar)
            if label != currentLabel {
                if !currentEntries.isEmpty {
                    groups.append(HistoryGroup(label: currentLabel, entries: currentEntries))
                }
                currentLabel = label
                currentEntries = [entry]
            } else {
                currentEntries.append(entry)
            }
        }
        if !currentEntries.isEmpty {
            groups.append(HistoryGroup(label: currentLabel, entries: currentEntries))
        }

        return groups
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInYesterday(date) { return "YESTERDAY" }

        let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if daysAgo < 7 { return date.formatted(.dateTime.weekday(.wide)).uppercased() }

        return date.formatted(.dateTime.month(.wide).day().year()).uppercased()
    }

    // MARK: - Row

    private func historyRow(_ entry: QuranReadingHistoryEntry) -> some View {
        Button {
            presentedDestination = HistoryDestination(
                chapterNumber: entry.chapterNumber,
                verseNumber: entry.verseNumber
            )
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                    Text("Sura \(entry.chapterNumber)")
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.accent)
                        .frame(width: 44, alignment: .leading)

                    Text(entry.chapterTitle)
                        .font(DS.Typography.eyebrowSM)

                    Spacer()

                    Text(entry.updatedAt.relativeCompact())
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.tertiary)
                }

                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    Text(entry.verseId)
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)

                    Text(entry.excerpt)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DS.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Extension

private extension Date {
    func relativeCompact() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 {
            let h = Int(interval / 3600)
            let m = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return m > 0 ? "\(h)h \(m)m ago" : "\(h)h ago"
        }
        let d = Int(interval / 86400)
        return "\(d)d ago"
    }
}
