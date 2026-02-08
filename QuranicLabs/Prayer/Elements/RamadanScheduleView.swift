import SwiftUI
import Defaults

struct Prayer_Element_RamadanScheduleView: View {
    @Default(.ramadan_cached_data) var cachedData

    var body: some View {
        Group {
            if let data = cachedData {
                ScrollView {
                    VStack(spacing: 16) {
                        // Current day info
                        if data.current_day > 0 {
                            Card(title: "Day \(data.current_day)", options: .init(
                                subtitle: data.status_string,
                                systemImage: "moon.stars",
                                style: .accent
                            ))
                        }

                        // Schedule table
                        Prayer_Element_RamadanScheduleTable(
                            schedule: data.schedule,
                            currentDay: data.current_day
                        )
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Schedule Available",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Open Ramadan from the Prayer tab to load the schedule.")
                )
            }
        }
        .navigationTitle("Ramadan Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}
