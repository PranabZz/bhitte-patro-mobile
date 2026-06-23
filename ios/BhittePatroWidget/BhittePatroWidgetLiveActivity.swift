//
//  BhittePatroWidgetLiveActivity.swift
//  BhittePatroWidget
//
//  Created by Pranab Kc on 23/06/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BhittePatroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BhittePatroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BhittePatroWidgetAttributes.self) { context in
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

extension BhittePatroWidgetAttributes {
    fileprivate static var preview: BhittePatroWidgetAttributes {
        BhittePatroWidgetAttributes(name: "World")
    }
}

extension BhittePatroWidgetAttributes.ContentState {
    fileprivate static var smiley: BhittePatroWidgetAttributes.ContentState {
        BhittePatroWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BhittePatroWidgetAttributes.ContentState {
         BhittePatroWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BhittePatroWidgetAttributes.preview) {
   BhittePatroWidgetLiveActivity()
} contentStates: {
    BhittePatroWidgetAttributes.ContentState.smiley
    BhittePatroWidgetAttributes.ContentState.starEyes
}
