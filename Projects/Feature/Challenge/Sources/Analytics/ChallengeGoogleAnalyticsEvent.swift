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
    static let weeklyChallengeShared = GoogleAnalyticsEvent(name: "weekly_challenge_share")

    static let challengeScreenView = GoogleAnalyticsEvent.screenView(.challenge)
    static let challengeChangeScreenView = GoogleAnalyticsEvent.screenView(.challengeChange)
    static let weeklyChallengeScreenView = GoogleAnalyticsEvent.screenView(.weeklyChallenge)

    /// 변경 전 챌린지를 알 수 없으면 `from_challenge`는 보내지 않습니다.
    static func challengeChanged(from: String?, to: String) -> GoogleAnalyticsEvent {
        var parameters = ["to_challenge": to]
        parameters["from_challenge"] = from
        return GoogleAnalyticsEvent(name: "challenge_change", parameters: parameters)
    }
}
