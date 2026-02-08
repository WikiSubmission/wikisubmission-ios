import SwiftUI
import Defaults

struct Home_PrayerSection: View {
    @Default(.prayer_times) var prayerTimes
    @ObservedObject var prayerManager = PrayerManager.shared
    @ObservedObject var router = Router.shared
    
    var body: some View {
        VStack {
            Text("PRAYER")
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(2)
            if let data = prayerManager.prayerData {
                VStack(spacing: 16) {
                    Prayer_Element_TimeCard(
                        data: data,
                        showLiveData: prayerManager.hasValidLiveData && NetworkManager.shared.hasInternet
                    )
                    Button {
                        router.selectTab(.prayer)
                    } label: {
                        Label("Prayer →", systemImage: "bolt.heart")
                    }
                    .pushToRight()
                    .buttonStyle(SignatureButtonStyle())

                    Prayer_Element_RamadanPreview()
                }
            } else {
                Card(title: "Set up now", options: .action(
                    systemImage: "bolt.heart",
                    showChevron: true,
                    style: .secondary
                ) {
                    router.selectTab(.prayer)
                })
            }
        }
    }
}
