//
//  OnBoardingGoogleAnalyticsEvent.swift
//  OnBoarding
//
//  Created by Jaewift on 11/12/26.
//

import CommonDomain
import CoreAnalyticsInterface

enum OnBoardingGoogleAnalyticsEvent {
    enum GrantStatus: String {
        case granted
        case denied
    }

    static let termsStepCompleted = GoogleAnalyticsEvent(
        name: "onboarding_step_complete",
        parameters: ["step_name": "terms"]
    )

    static func notificationPermissionResult(_ status: GrantStatus) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "permission_result",
            parameters: [
                "permission_type": "notification",
                "grant_status": status.rawValue
            ]
        )
    }

    static func signedUp(method: SocialLoginType) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "sign_up",
            parameters: ["method": method.googleAnalyticsValue]
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
