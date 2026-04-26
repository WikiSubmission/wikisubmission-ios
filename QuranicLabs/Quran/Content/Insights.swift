import SwiftUI
import Charts

// MARK: - Supporting Types

struct DailyReading: Identifiable {
    let date: Date
    let label: String
    let minutes: Double
    var id: Date { date }
}

struct ChapterFrequency: Identifiable {
    let chapterNumber: Int
    let chapterTitle: String
    let count: Int
    var id: Int { chapterNumber }
}

// MARK: - Store Extensions

extension QuranReadingHistoryStore {

    private static let minimumSessionDuration: TimeInterval = 15

    func sessionDuration(_ session: QuranReadingSession) -> TimeInterval {
        max(session.duration, Self.minimumSessionDuration)
    }

    var hasReadToday: Bool {
        history.contains { Calendar.current.isDateInToday($0.startedAt) }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDay = today

        if !hasReadToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDay = yesterday
        }

        while true {
            let dayStart = checkDay
            if history.contains(where: { calendar.startOfDay(for: $0.startedAt) == dayStart }) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
                checkDay = prev
            } else {
                break
            }
        }
        return streak
    }

    var totalReadingTime: TimeInterval {
        history.reduce(0) { $0 + sessionDuration($1) }
    }

    var totalSessions: Int { history.count }

    var totalEvents: Int {
        history.reduce(0) { $0 + $1.events.count }
    }

    var uniqueChaptersVisited: Int {
        Set(history.filter { $0.chapterNumber > 0 }.map(\.chapterNumber)).count
    }

    var topChapters: [ChapterFrequency] {
        let relevant = history.filter { $0.chapterNumber > 0 }
        let grouped = Dictionary(grouping: relevant, by: \.chapterNumber)
        return grouped.map { ChapterFrequency(chapterNumber: $0.key, chapterTitle: $0.value.first?.chapterTitle ?? "", count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var mostReadChapter: ChapterFrequency? { topChapters.first }

    var averageSessionDuration: TimeInterval {
        guard !history.isEmpty else { return 0 }
        return totalReadingTime / Double(history.count)
    }

    var averageEventsPerSession: Double {
        guard !history.isEmpty else { return 0 }
        return Double(totalEvents) / Double(history.count)
    }

    var last7DaysActivity: [DailyReading] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let sessions = history.filter { calendar.startOfDay(for: $0.startedAt) == day }
            let minutes = sessions.reduce(0.0) { $0 + sessionDuration($1) / 60.0 }
            return DailyReading(date: day, label: formatter.string(from: day), minutes: minutes)
        }
    }

    var weeklyMinutes: Int {
        Int(last7DaysActivity.reduce(0) { $0 + $1.minutes })
    }

    var actionBreakdown: [(action: ReadingAction, count: Int)] {
        let grouped = Dictionary(grouping: history, by: \.action)
        return ReadingAction.allCases.compactMap { act in
            guard let count = grouped[act]?.count, count > 0 else { return nil }
            return (action: act, count: count)
        }
    }
}

// MARK: - Formatting

private func formattedDuration(_ interval: TimeInterval) -> String {
    let totalSeconds = Int(interval)
    if totalSeconds < 60 { return totalSeconds > 0 ? "<1m" : "0m" }
    let totalMinutes = totalSeconds / 60
    if totalMinutes < 60 { return "\(totalMinutes)m" }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
}

// MARK: - Card Container

private struct InsightCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
            )
    }
}

// MARK: - Insights View

struct Quran_Content_Insights: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared
    @ObservedObject private var router = Router.shared

    private let mono = DS.Font.mono(10, weight: .regular)
    private let monoMed = DS.Font.mono(10, weight: .medium)
    private let monoSm = DS.Font.mono(9, weight: .regular)
    private let statFont = Font.system(size: 28, weight: .semibold, design: .rounded)

    var body: some View {
        Group {
            if store.history.isEmpty {
                emptyState
            } else {
                insightsContent
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Insights Yet")
                .font(DS.Typography.titleLG)
            Text("Start reading to see your activity here.")
                .font(DS.Typography.bodySM)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                router.selectTab(.quran)
                router.popToRoot(for: .quran)
            } label: {
                Label("Browse Quran", systemImage: "book.closed")
                    .font(DS.Typography.eyebrow)
            }
            .buttonStyle(SignatureButtonStyle())
            .padding(.top, DS.Spacing.sm)
            Spacer()
        }
    }

    // MARK: - Content

    private var insightsContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DS.Spacing.xl) {
                streakCard
                weeklyChart
                statsGrid
                topChaptersCard
                activitySummary
                activityLink
            }
            .padding(.horizontal)
            .padding(.bottom, 200)
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        let readToday = store.hasReadToday
        let streak = store.currentStreak

        return InsightCard {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: readToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(readToday ? .green : .secondary)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(readToday ? "Read Today" : "Not Yet Today")
                        .font(DS.Typography.titleSM)
                    Text(streak > 0 ? "\(streak)-day streak" : "Start a streak")
                        .font(monoSm)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                        Text("\(streak)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        let activity = store.last7DaysActivity
        let weekTotal = store.weeklyMinutes
        let todayStart = Calendar.current.startOfDay(for: Date())

        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionLabel("THIS WEEK")

            InsightCard {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Chart(activity) { day in
                        BarMark(
                            x: .value("Day", day.label),
                            y: .value("Minutes", day.minutes)
                        )
                        .foregroundStyle(day.date == todayStart ? Color.accentColor : Color.accentColor.opacity(0.45))
                        .cornerRadius(DS.Radius.sm)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(DS.Color.rule)
                            AxisValueLabel()
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(DS.Color.fgMuted)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(DS.Color.fgMuted)
                        }
                    }
                    .frame(height: 180)

                    Text("\(weekTotal) MIN THIS WEEK")
                        .font(monoSm)
                        .foregroundStyle(DS.Color.fgMuted)
                        .tracking(1.5)
                }
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
            statCell(value: "\(store.totalSessions)", label: "SESSIONS")
            statCell(value: formattedDuration(store.totalReadingTime), label: "TOTAL TIME")
            statCell(value: "\(store.uniqueChaptersVisited)", label: "CHAPTERS")
            statCell(value: formattedDuration(store.averageSessionDuration), label: "AVG SESSION")
            statCell(value: "\(store.totalEvents)", label: "EVENTS")
            statCell(value: String(format: "%.1f", store.averageEventsPerSession), label: "EVENTS / SESSION")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        InsightCard {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(value)
                    .font(statFont)
                    .foregroundStyle(DS.Color.fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(monoSm)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.fgMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Top Chapters

    private var topChaptersCard: some View {
        let top = Array(store.topChapters.prefix(5))
        let maxCount = top.first?.count ?? 1

        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionLabel("TOP CHAPTERS")

            InsightCard {
                VStack(spacing: DS.Spacing.sm) {
                    ForEach(top) { chapter in
                        HStack(spacing: DS.Spacing.sm) {
                            Text("\(chapter.chapterNumber)")
                                .font(monoSm)
                                .foregroundStyle(DS.Color.fgMuted)
                                .frame(width: 20, alignment: .trailing)

                            Text(chapter.chapterTitle)
                                .font(mono)
                                .foregroundStyle(DS.Color.fg)
                                .lineLimit(1)
                                .frame(width: 80, alignment: .leading)

                            GeometryReader { geo in
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.5))
                                    .frame(width: geo.size.width * CGFloat(chapter.count) / CGFloat(maxCount))
                            }
                            .frame(height: 4)

                            Text("\(chapter.count)")
                                .font(monoMed)
                                .foregroundStyle(DS.Color.fgMuted)
                                .frame(width: 20, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Summary (action breakdown)

    private var activitySummary: some View {
        let actions = store.actionBreakdown

        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionLabel("ACTIVITY BREAKDOWN")

            InsightCard {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ForEach(actions, id: \.action) { item in
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: item.action.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.accent)
                                .frame(width: 16)

                            Text(item.action.verb.uppercased())
                                .font(monoMed)
                                .foregroundStyle(.accent)

                            Spacer()

                            Text("\(item.count)")
                                .font(monoMed)
                                .foregroundStyle(DS.Color.fgMuted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Link

    private var activityLink: some View {
        NavigationLink(value: Router.Destination.readingHistory) {
            HStack {
                Label("Activity Log", systemImage: "clock.arrow.circlepath")
                    .font(DS.Typography.label)
                Spacer()
                Text("\(store.totalSessions) sessions")
                    .font(monoSm)
                    .foregroundStyle(DS.Color.fgMuted)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DS.Color.fgMuted)
            }
            .foregroundStyle(DS.Color.fg)
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Card (for Activity header)

struct InsightsMiniCard: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared
    private let monoSm = DS.Font.mono(9, weight: .regular)
    private let detailFont = Font.system(size: 22, weight: .semibold, design: .rounded)

    var body: some View {
        NavigationLink(value: Router.Destination.insights) {
            HStack(spacing: DS.Spacing.md) {
                Chart(store.last7DaysActivity) { day in
                    BarMark(
                        x: .value("Day", day.label),
                        y: .value("Min", day.minutes)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(1)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 80, height: 36)

                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text("THIS WEEK")
                        .font(monoSm)
                        .tracking(2)
                        .foregroundStyle(DS.Color.fgMuted)
                    Text(store.weeklyMinutes > 0 ? "\(store.weeklyMinutes) min" : "No activity")
                        .font(detailFont)
                        .foregroundStyle(DS.Color.fg)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DS.Color.fgMuted)
            }
            .padding(DS.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(DS.Color.rule, lineWidth: DS.Hairline.width)
            )
        }
        .buttonStyle(.plain)
    }
}
