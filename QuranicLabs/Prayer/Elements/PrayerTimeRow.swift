import SwiftUI

struct Prayer_Element_TimeRow: View {
    let prayer: PrayerName
    let time: String
    let isCurrent: Bool
    let isUpcoming: Bool
    let elapsed: String?
    let timeLeft: String?
    let showLiveData: Bool

    init(
        prayer: PrayerName,
        time: String,
        isCurrent: Bool = false,
        isUpcoming: Bool = false,
        elapsed: String? = nil,
        timeLeft: String? = nil,
        showLiveData: Bool = true
    ) {
        self.prayer = prayer
        self.time = time
        self.isCurrent = isCurrent
        self.isUpcoming = isUpcoming
        self.elapsed = elapsed
        self.timeLeft = timeLeft
        self.showLiveData = showLiveData
    }

    private var isSunrise: Bool {
        prayer == .sunrise
    }

    private var accentColor: Color {
        if isSunrise {
            return .orange
        }
        return isCurrent && showLiveData ? .accentColor : .primary
    }

    private var backgroundColor: Color {
        if isSunrise && isCurrent && showLiveData {
            return Color.orange.opacity(0.12)
        }
        return isCurrent && showLiveData ? Color.accentColor.opacity(0.12) : .clear
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Left side: name + timing info
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                HStack {
                    Image(systemName: prayer.symbol)
                        .frame(width: 20)
                    Text(prayer.englishName)
                }
                .fontWeight(isCurrent && showLiveData ? .bold : .regular)

                Group {
                    if isSunrise {
                        // Current prayer elapsed time
                        if isCurrent && showLiveData, let elapsed {
                            Label("\(elapsed) ago", systemImage: "clock")
                                .foregroundStyle(elapsed.contains("h") ? .orange : .red)
                        }

                        // Upcoming prayer time left
                        if isUpcoming && showLiveData, let timeLeft {
                            Text("in \(timeLeft)")
                                .foregroundStyle(timeLeft.contains("h") ? .gray : .red)
                        }
                    } else {
                        // Current prayer elapsed time
                        if isCurrent && showLiveData, let elapsed {
                            Label("\(elapsed) ago", systemImage: "clock")
                                .foregroundStyle(elapsed.contains("h") ? .accent : .red)
                        }

                        // Upcoming prayer time left
                        if isUpcoming && showLiveData, let timeLeft {
                            Text("in \(timeLeft)")
                                .foregroundStyle(timeLeft.contains("h") ? .gray : .red)
                        }
                    }
                }
                .fontWeight(isCurrent && showLiveData ? .bold : .regular)
            }

            Spacer()

            // Right side: time
            Group {
                Text(time)
                    .fontWeight(isCurrent && showLiveData ? .bold : .regular)
            }
        }
        .font(.caption)
        .monospaced()
        .foregroundColor(accentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
}
