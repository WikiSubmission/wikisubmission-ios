import WidgetKit
import SwiftUI

/// Entry point for the Salat Live Activity extension.
///
/// Deliberately contains only the Live Activity for now; if the home screen
/// widget from the October 2025 branch is ever revived it slots in here as a
/// second entry.
@main
struct SalatActivityBundle: WidgetBundle {
    var body: some Widget {
        SalatLiveActivity()
    }
}
