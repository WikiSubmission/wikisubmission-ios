import SwiftUI

struct Prayer_Element_PrayerSchedule: View {
    let schedule: [PrayerScheduleDay]

    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Header button
            Card(title: "30-Day Schedule", options: .destination(
                systemImage: "calendar"
            ){
                ScrollView {
                    scheduleContent
                        .padding(.top, 16)
                }
                .padding()
                .navigationTitle("30 Day Schedule")
                .navigationBarTitleDisplayMode(.inline)
            })
        }
    }

    private var scheduleContent: some View {
        VStack(spacing: 16) {
            // Day selector
            daySelector

            // Selected day's prayer times
            if selectedIndex < schedule.count {
                dayDetail(schedule[selectedIndex])
            }
        }
    }

    private var daySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(schedule.enumerated()), id: \.element.id) { index, day in
                        dayPill(day, index: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onAppear {
                // Start at today
                if let todayIndex = schedule.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
                    selectedIndex = todayIndex
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(todayIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private func dayPill(_ day: PrayerScheduleDay, index: Int) -> some View {
        let isSelected = selectedIndex == index
        let isToday = Calendar.current.isDateInToday(day.date)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
            }
        } label: {
            VStack(spacing: 4) {
                Text(dayAbbreviation(from: day.day))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .monospaced()
            .frame(width: 44, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func dayDetail(_ day: PrayerScheduleDay) -> some View {
        VStack(spacing: 8) {
            // Date header
            Text(day.day)
                .font(.caption)
                .monospaced()
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Prayer times
            VStack(spacing: 4) {
                prayerRow(name: "Dawn", time: day.times.fajr, symbol: "moon.stars")
                prayerRow(name: "Noon", time: day.times.dhuhr, symbol: "sun.max")
                prayerRow(name: "Afternoon", time: day.times.asr, symbol: "sun.haze")
                prayerRow(name: "Sunset", time: day.times.maghrib, symbol: "sunset")
                prayerRow(name: "Night", time: day.times.isha, symbol: "moon")
            }

            // Sunrise separated below
            Text("Sunrise at \(day.times.sunrise)")
                .font(.caption)
                .monospaced()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func prayerRow(name: String, time: String, symbol: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .frame(width: 20)
                Text(name)
            }

            Spacer()

            Text(time)
        }
        .font(.caption)
        .monospaced()
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
    }

    private func dayAbbreviation(from dayString: String) -> String {
        // Extract first 3 letters (e.g., "Wed" from "Wednesday, January 21st")
        String(dayString.prefix(3))
    }
}
