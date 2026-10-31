//
//  ChallengeGoogleAnalyticsEvent.swift
//  Challenge
//
//  Created by Jaewift on 10/31/26.
//

import CoreAnalyticsInterface

enum ChallengeGoogleAnalyticsEvent {
    static let pokeSent = GoogleAnalyticsEvent(name: "poke_send")
    static let weeklyChallengeCompleted = GoogleAnalyticsEvent(name: "weekly_challenge_complete")
}
