//
//  SignInGoogleAnalyticsEvent.swift
//  SignIn
//
//  Created by Jaewift on 11/12/26.
//

import CommonDomain
import CoreAnalyticsInterface

enum SignInGoogleAnalyticsEvent {
    enum LoginFailReason: String {
        case cancel
        case error
    }

    static let loginScreenView = GoogleAnalyticsEvent.screenView(.login)

    static func loginSucceeded(method: SocialLoginType) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "login",
            parameters: ["method": method.googleAnalyticsValue]
        )
    }

    static func loginFailed(
        method: SocialLoginType,
        reason: LoginFailReason
    ) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "login_fail",
            parameters: [
                "method": method.googleAnalyticsValue,
                "fail_reason": reason.rawValue
            ]
        )
    }
}

private extension SocialLoginType {
    var googleAnalyticsValue: String {
        switch self {
        case .kakao: "kakao"
        case .apple: "apple"
        case .iosTest: "review"
        }
    }
}
