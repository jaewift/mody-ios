//
//  GoogleAnalyticsScreen.swift
//  CoreAnalyticsInterface
//
//  Created by Jaewift on 11/12/26.
//

/// GA4 이벤트 명세서에서 확정한 `screen_name` 값입니다. Android와 같은 값을 사용합니다.
public enum GoogleAnalyticsScreen: String, CaseIterable {
    case login = "Login"
    case terms = "Terms"
    case termsDetail = "TermsDetail"
    case nickname = "Nickname"
    case birth = "Birth"
    case weight = "Weight"
    case alarm = "Alarm"
    case permission = "Permission"
    case groupJoin = "GroupJoin"
    case groupCreate = "GroupCreate"
    case codeShare = "CodeShare"
    case feed = "Feed"
    case challenge = "Challenge"
    case challengeChange = "ChallengeChange"
    case weeklyChallenge = "WeeklyChallenge"
}
