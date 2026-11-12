//
//  CoreKakaoAuthService.swift
//  CoreKakao
//
//  Created by 김동준 on 7/7/26
//

import CoreKakaoInterface
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon

public final class CoreKakaoAuthService: CoreKakaoAuthInterface {
    public init() {}

    @MainActor
    public func signInWithKakao() async throws -> String {
        do {
            let token: OAuthToken

            if UserApi.isKakaoTalkLoginAvailable() {
                token = try await loginWithKakaoTalk()
            } else {
                token = try await loginWithKakaoAccount()
            }

            return token.accessToken
        } catch let error as SdkError {
            if error.isCancelledByUser {
                throw CoreKakaoAuthError.cancelled
            }
            print("TODO: Handle Kakao SDK login error: \(error)")
            throw error
        } catch {
            print("TODO: Handle unknown Kakao login error: \(error)")
            throw error
        }
    }
}

private extension SdkError {
    /// 카카오계정 로그인은 `Cancelled`, 카카오톡 로그인은 `AccessDenied`로 취소를 알려줍니다.
    var isCancelledByUser: Bool {
        if isClientFailed {
            return getClientError().reason == .Cancelled
        }

        if isAuthFailed {
            return getAuthError().reason == .AccessDenied
        }

        return false
    }
}
