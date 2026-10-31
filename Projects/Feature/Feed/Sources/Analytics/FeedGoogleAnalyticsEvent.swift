//
//  FeedGoogleAnalyticsEvent.swift
//  Feed
//
//  Created by Jaewift on 10/31/26.
//

import CoreAnalyticsInterface

enum FeedGoogleAnalyticsEvent {
    static func groupSelectorClicked(groupCount: Int) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_selector_click",
            parameters: ["group_count": String(groupCount)]
        )
    }

    static func groupAddClicked(groupCount: Int) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_add_click",
            parameters: ["group_count": String(groupCount)]
        )
    }

    static let pokeCTAClicked = GoogleAnalyticsEvent(name: "poke_cta_click")
}
