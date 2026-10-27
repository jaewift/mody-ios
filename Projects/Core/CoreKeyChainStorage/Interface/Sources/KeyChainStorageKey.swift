//
//  KeyChainStorageKey.swift
//  CoreKeyChainStorageInterface
//
//  Created by 김동준 on 7/2/26
//

public enum KeyChainStorageKey: String {
    case isSignUpDone = "isSignUpDone"
    case mainAccessible = "mainAccessible"
    case groupOnboardingCompleted = "groupOnboardingCompleted"
    case accessToken = "accessToken"
    case refreshToken = "refreshToken"
    case socialLoginType = "socialLoginType"
    // 앱 이전 후 서버에서 무효 처리된 토큰을 모든 기기가 한 번씩 재등록하도록 키를 변경
    case fcmToken = "fcmTokenV2"
}
