//
//  AuthRepositoryProtocol.swift
//  CoreAuthInterface
//
//  Created by 김동준 on 7/2/26
//

import CommonDomain

public protocol AuthRepositoryProtocol {
    func getSignIn(
        loginType: SocialLoginType,
        accessToken: String
    ) async throws -> AuthSession

    func getUserInfo(needUpdateKeyChain: Bool) async throws -> UserInfo
    func postLogout() async throws
    func deleteAccount() async throws
    /// 마지막으로 로그인한 소셜 로그인 방식입니다. 로그인 기록이 없으면 nil입니다.
    func getSocialLoginType() -> SocialLoginType?
}
