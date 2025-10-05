import Defaults

extension Defaults.Keys {
    static let onboarded = Key<Bool>("onboarded", default: false)
    static let prompted_for_notifications = Key<Bool>("prompted_for_notifications", default: false)
    static let active_tab = Key<TabItem>("active_tab", default: .home)
}

extension Defaults {
    static func resetOnboardedState() {
        Defaults.Keys.onboarded.reset()
        Defaults.Keys.active_tab.reset()
    }
}
