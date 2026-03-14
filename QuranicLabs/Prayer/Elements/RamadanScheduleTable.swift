import SwiftUI

struct Prayer_Element_RamadanScheduleTable: View {
    let schedule: [RamadanDay]
    let currentDay: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(schedule) { day in
                RamadanDayCard(
                    day: day,
                    currentDay: currentDay,
                    colorScheme: colorScheme
                )
            }
        }
    }
}

private struct RamadanDayCard: View {
    let day: RamadanDay
    let currentDay: Int
    let colorScheme: ColorScheme

    private var isCurrentDay: Bool { day.day_number == currentDay }
    private var isPast: Bool { day.day_number < currentDay }

    var body: some View {
        VStack(spacing: 0) {
            // Header row with day number and date
            headerRow

            // Times grid
            timesGrid
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentDay ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isCurrentDay ? 2 : 1)
        )
        .opacity(isPast ? 0.6 : 1)
    }

    private var cardBackground: some View {
        Group {
            if isCurrentDay {
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
                    .fill(isCurrentDay ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("\(day.day_number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentDay ? .white : .primary)
            }

            // Date info
            VStack(alignment: .leading, spacing: 2) {
                Text(formatFullDate(day.day))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            // Fasting duration indicator
            if !isPast {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(fastingDuration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("fasting")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var timesGrid: some View {
        HStack(spacing: 0) {
            timeCell(label: "Dawn", time: formattedTime(day.dawn), icon: "moon.stars.fill", color: .indigo)
            divider
            timeCell(label: "Sunrise", time: formattedTime(day.sunrise), icon: "sunrise.fill", color: .orange)
            divider
            timeCell(label: "Noon", time: formattedTime(day.noon), icon: "sun.max.fill", color: .yellow)
            divider
            timeCell(label: "Afternoon", time: formattedTime(day.afternoon), icon: "sun.haze.fill", color: .orange)
            divider
            timeCell(label: "Sunset", time: formattedTime(day.sunset), icon: "sunset.fill", color: .red)
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

    private func timeCell(label: String, time: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(isPast ? .secondary : color)
            Text(time)
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var fastingDuration: String {
        // Calculate approximate fasting duration from dawn to sunset
        guard let dawnTime = parseTime(day.dawn),
              let sunsetTime = parseTime(day.sunset) else {
            return ""
        }

        let minutes = Int(sunsetTime.timeIntervalSince(dawnTime) / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.date(from: timeString)
    }

    private func formattedTime(_ raw: String) -> String {
        guard let date = parseTime(raw) else { return raw }
        let display = DateFormatter()
        display.locale = Locale.current
        display.dateStyle = .none
        display.timeStyle = .short
        return display.string(from: date)
    }

    private func formatFullDate(_ dateString: String) -> String {
        // "Saturday, March 1, 2026" -> "Saturday, Mar 1"
        let components = dateString.components(separatedBy: ", ")
        if components.count >= 2 {
            let weekday = components[0]
            let monthDay = components[1]
            let parts = monthDay.components(separatedBy: " ")
            if parts.count >= 2 {
                let month = String(parts[0].prefix(3))
                return "\(weekday), \(month) \(parts[1])"
            }
        }
        return dateString
    }
}
