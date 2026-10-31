//
//  ModyGroupGoogleAnalyticsEvent.swift
//  ModyGroup
//
//  Created by Jaewift on 10/31/26.
//

import CoreAnalyticsInterface

enum ModyGroupGoogleAnalyticsEvent {
    enum ShareMethod: String {
        case kakao
        case copy
    }

    static func groupShareClicked(method: ShareMethod) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_share_click",
            parameters: ["share_method": method.rawValue]
        )
    }

    static let groupCreateFinished = GoogleAnalyticsEvent(name: "group_create_finish")
}
