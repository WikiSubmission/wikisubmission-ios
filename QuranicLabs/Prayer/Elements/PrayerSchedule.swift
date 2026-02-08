import SwiftUI

struct Prayer_Element_PrayerSchedule: View {
    let schedule: [PrayerScheduleDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Card(title: "30-Day Schedule", options: .destination(
                systemImage: "calendar"
            ) {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(schedule) { day in
                            PrayerDayCard(day: day)
                        }
                    }
                    .padding()
                }
                .navigationTitle("30 Day Schedule")
                .navigationBarTitleDisplayMode(.inline)
            })
        }
    }
}

private struct PrayerDayCard: View {
    let day: PrayerScheduleDay

    @Environment(\.colorScheme) private var colorScheme

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    private var isPast: Bool {
        Calendar.current.compare(day.date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            timesGrid
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isToday ? 2 : 1)
        )
        .opacity(isPast ? 0.6 : 1)
    }

    private var cardBackground: some View {
        Group {
            if isToday {
                Color.accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08)
            } else {
                Color(UIColor.secondarySystemBackground)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            // Day number badge
            ZStack {
                Circle()
                    .fill(isToday ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isToday ? .white : .primary)
            }

            // Date info
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(day.day))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var timesGrid: some View {
        HStack(spacing: 0) {
            timeCell(prayer: .fajr, time: day.times.fajr)
            divider
            timeCell(prayer: .sunrise, time: day.times.sunrise)
            divider
            timeCell(prayer: .dhuhr, time: day.times.dhuhr)
            divider
            timeCell(prayer: .asr, time: day.times.asr)
            divider
            timeCell(prayer: .maghrib, time: day.times.maghrib)
            divider
            timeCell(prayer: .isha, time: day.times.isha)
        }
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.1 : 0.04))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    private func timeCell(prayer: PrayerName, time: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: prayer.symbol)
                .font(.caption)
                .foregroundStyle(isPast ? .secondary : colorForPrayer(prayer))
            Text(time)
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
            Text(prayer.englishName)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func colorForPrayer(_ prayer: PrayerName) -> Color {
        switch prayer {
        case .fajr: return .indigo
        case .sunrise: return .orange
        case .dhuhr: return .yellow
        case .asr: return .orange
        case .maghrib: return .red
        case .isha: return .purple
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // "Wednesday, January 21st" -> "Wednesday, Jan 21"
        let components = dateString.components(separatedBy: ", ")
        if components.count >= 2 {
            let weekday = components[0]
            let monthDay = components[1]
            let parts = monthDay.components(separatedBy: " ")
            if parts.count >= 2 {
                let month = String(parts[0].prefix(3))
                // Remove ordinal suffix (st, nd, rd, th)
                var dayNum = parts[1]
                dayNum = dayNum.replacingOccurrences(of: "st", with: "")
                dayNum = dayNum.replacingOccurrences(of: "nd", with: "")
                dayNum = dayNum.replacingOccurrences(of: "rd", with: "")
                dayNum = dayNum.replacingOccurrences(of: "th", with: "")
                return "\(weekday), \(month) \(dayNum)"
            }
        }
        return dateString
    }
}
