import Foundation
import Defaults

extension Defaults.Keys {
    static let onboarded = Key<Bool>("onboarded", default: false)
    static let prompted_for_notifications = Key<Bool>("prompted_for_notifications", default: false)
    static let active_tab = Key<TabItem>("active_tab", default: .home)
    static let last_checked_for_update = Key<Date?>("last_checked_for_update", default: nil)
    static let qibla_enabled = Key<Bool>("qibla_enabled", default: false)
}

extension Defaults {
    static func resetOnboardedState() {
        Defaults.Keys.onboarded.reset()
        Defaults.Keys.active_tab.reset()
        Defaults.Keys.last_checked_for_update.reset()
    }
}
