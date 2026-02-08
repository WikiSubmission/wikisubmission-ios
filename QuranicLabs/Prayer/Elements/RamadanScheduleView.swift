import SwiftUI
import Defaults

struct Prayer_Element_RamadanScheduleView: View {
    @Default(.ramadan_cached_data) var cachedData

    var body: some View {
        Group {
            if let data = cachedData {
                ScrollView {
                    Prayer_Element_RamadanScheduleTable(
                        schedule: data.schedule,
                        currentDay: data.current_day
                    )
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
