import SwiftUI
import Defaults

struct Prayer_Element_RamadanScheduleTable: View {
    let schedule: [RamadanDay]
    let currentDay: Int

    @Default(.prayer_times_location) var location
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ForEach(schedule) { day in
                RamadanDayRow(
                    day: day,
                    currentDay: currentDay,
                    isLastRow: day.day_number == schedule.count,
                    colorScheme: colorScheme
                )
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Day")
                .frame(width: 44)
            Text("Date")
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: "sunrise.fill")
                    .font(.caption2)
                Text("Dawn")
            }
            .frame(width: 80)
            HStack(spacing: 4) {
                Image(systemName: "sunset.fill")
                    .font(.caption2)
                Text("Sunset")
            }
            .frame(width: 72)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.08))
    }
}

private struct RamadanDayRow: View {
    let day: RamadanDay
    let currentDay: Int
    let isLastRow: Bool
    let colorScheme: ColorScheme

    private var isCurrentDay: Bool { day.day_number == currentDay }
    private var isPast: Bool { day.day_number < currentDay }

    var body: some View {
        VStack(spacing: 0) {
            rowContent
            if !isLastRow {
                Divider()
                    .padding(.leading, isCurrentDay ? 0 : 56)
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 0) {
            dayNumberView
            dateView
            dawnView
            sunsetView
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCurrentDay ? Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1) : Color.clear)
    }

    private var dayNumberView: some View {
        ZStack {
            if isCurrentDay {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)
            }
            Text("\(day.day_number)")
                .font(.subheadline)
                .fontWeight(isCurrentDay ? .bold : .regular)
                .foregroundColor(isCurrentDay ? .white : (isPast ? .secondary : .primary))
        }
        .frame(width: 44)
    }

    private var dateView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formatWeekday(day.day))
                .font(.subheadline)
                .fontWeight(isCurrentDay ? .semibold : .regular)
                .foregroundColor(isPast ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dawnView: some View {
        Text(day.dawn)
            .font(.subheadline.monospacedDigit())
            .fontWeight(isCurrentDay ? .semibold : .regular)
            .foregroundColor(isPast ? .secondary : .primary)
            .frame(width: 80)
    }

    private var sunsetView: some View {
        Text(day.sunset)
            .font(.subheadline.monospacedDigit())
            .fontWeight(isCurrentDay ? .semibold : .regular)
            .foregroundColor(isPast ? .secondary : (isCurrentDay ? .accentColor : .primary))
            .frame(width: 72)
    }

    private func formatWeekday(_ dateString: String) -> String {
        let components = dateString.components(separatedBy: ", ")
        return components.first ?? dateString
    }

    private func formatDate(_ dateString: String) -> String {
        let components = dateString.components(separatedBy: ", ")
        if components.count >= 2 {
            let monthDay = components[1]
            let parts = monthDay.components(separatedBy: " ")
            if parts.count >= 2 {
                let month = String(parts[0].prefix(3))
                return "\(month) \(parts[1])"
            }
        }
        return dateString
    }
}
