import SwiftUI
import Charts

// MARK: - Store Extensions

struct DailyReading: Identifiable {
    let date: Date
    let label: String
    let minutes: Double
    var id: Date { date }
}

struct ChapterFrequency {
    let chapterNumber: Int
    let chapterTitle: String
    let count: Int
}

extension QuranReadingHistoryStore {

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
            let hasEntry = history.contains { calendar.startOfDay(for: $0.startedAt) == dayStart }
            if hasEntry {
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
        history.reduce(0) { sum, entry in
            sum + min(entry.updatedAt.timeIntervalSince(entry.startedAt), 1200)
        }
    }

    var totalVersesRead: Int { history.count }

    var uniqueChaptersVisited: Int {
        Set(history.map(\.chapterNumber)).count
    }

    var mostReadChapter: ChapterFrequency? {
        let grouped = Dictionary(grouping: history, by: \.chapterNumber)
        guard let top = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        let title = top.value.first?.chapterTitle ?? ""
        return ChapterFrequency(chapterNumber: top.key, chapterTitle: title, count: top.value.count)
    }

    var averageSessionDuration: TimeInterval {
        guard !history.isEmpty else { return 0 }
        return totalReadingTime / Double(history.count)
    }

    var last7DaysActivity: [DailyReading] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let entries = history.filter { calendar.startOfDay(for: $0.startedAt) == day }
            let minutes = entries.reduce(0.0) { sum, entry in
                sum + min(entry.updatedAt.timeIntervalSince(entry.startedAt), 1200) / 60.0
            }
            return DailyReading(
                date: day,
                label: formatter.string(from: day),
                minutes: minutes
            )
        }
    }

    var weeklyMinutes: Int {
        Int(last7DaysActivity.reduce(0) { $0 + $1.minutes })
    }
}

// MARK: - Formatting Helpers

private func formattedDuration(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval / 60)
    if totalMinutes < 60 {
        return "\(totalMinutes)m"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
}

/// Large rounded number for stat display (Apple Health style)
private let statNumberFont = Font.system(size: 28, weight: .semibold, design: .rounded)
/// Medium rounded number for detail cards
private let detailNumberFont = Font.system(size: 22, weight: .semibold, design: .rounded)

// MARK: - Reusable card background

private struct InsightCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

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

// MARK: - Full Insights View

struct Quran_Content_Insights: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared
    @ObservedObject private var router = Router.shared

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

    // MARK: - Empty State

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
                dailyCheckIn
                statsRow
                weeklyChart
                detailCards
            }
            .padding(.horizontal)
            .padding(.bottom, 200)
        }
    }

    // MARK: - Daily Check-In

    private var dailyCheckIn: some View {
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
                        .font(DS.Typography.eyebrowSM)
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

    // MARK: - Stats Row

    private var statsRow: some View {
        InsightCard {
            HStack(spacing: 0) {
                statItem(
                    value: "\(store.currentStreak)",
                    label: "DAY STREAK",
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                statItem(
                    value: formattedDuration(store.totalReadingTime),
                    label: "TOTAL TIME",
                    alignment: .center
                )
                .frame(maxWidth: .infinity)

                statItem(
                    value: "\(store.totalVersesRead)",
                    label: "SESSIONS",
                    alignment: .trailing
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func statItem(value: String, label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: DS.Spacing.xs) {
            Text(value)
                .font(statNumberFont)
                .foregroundStyle(DS.Color.fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(DS.Typography.eyebrowSM)
                .tracking(1.5)
                .foregroundStyle(DS.Color.fgMuted)
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

                    Text("\(weekTotal) min this week".uppercased())
                        .font(DS.Typography.eyebrowSM)
                        .foregroundStyle(DS.Color.fgMuted)
                        .tracking(1.5)
                }
            }
        }
    }

    // MARK: - Detail Cards

    private var detailCards: some View {
        HStack(spacing: DS.Spacing.sm) {
            InsightCard {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(store.mostReadChapter?.chapterTitle ?? "—")
                        .font(detailNumberFont)
                        .foregroundStyle(DS.Color.fg)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("MOST READ")
                        .font(DS.Typography.eyebrowSM)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.fgMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            InsightCard {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(formattedDuration(store.averageSessionDuration))
                        .font(detailNumberFont)
                        .foregroundStyle(DS.Color.fg)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("AVG SESSION")
                        .font(DS.Typography.eyebrowSM)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.fgMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Insights Mini Card (for ReadingHistory header)

struct InsightsMiniCard: View {
    @ObservedObject private var store = QuranReadingHistoryStore.shared

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
                        .font(DS.Typography.eyebrowSM)
                        .tracking(2)
                        .foregroundStyle(DS.Color.fgMuted)
                    Text(store.weeklyMinutes > 0 ? "\(store.weeklyMinutes) min" : "No activity")
                        .font(detailNumberFont)
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
