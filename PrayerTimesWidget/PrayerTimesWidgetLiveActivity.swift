//
//  PrayerTimesWidgetLiveActivity.swift
//  PrayerTimesWidget
//
//  Created by down time on 11/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PrayerTimesWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PrayerTimesWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerTimesWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension PrayerTimesWidgetAttributes {
    fileprivate static var preview: PrayerTimesWidgetAttributes {
        PrayerTimesWidgetAttributes(name: "World")
    }
}

extension PrayerTimesWidgetAttributes.ContentState {
    fileprivate static var smiley: PrayerTimesWidgetAttributes.ContentState {
        PrayerTimesWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PrayerTimesWidgetAttributes.ContentState {
         PrayerTimesWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PrayerTimesWidgetAttributes.preview) {
   PrayerTimesWidgetLiveActivity()
} contentStates: {
    PrayerTimesWidgetAttributes.ContentState.smiley
    PrayerTimesWidgetAttributes.ContentState.starEyes
}
