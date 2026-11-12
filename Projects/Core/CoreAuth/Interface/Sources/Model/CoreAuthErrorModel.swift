//
//  CoreAuthErrorModel.swift
//  CoreAuth
//
//  Created by 김동준 on 7/2/26
//

public enum CoreAuthErrorModel: Error {
    case unKnownError
    /// 사용자가 소셜 로그인을 취소했습니다.
    case socialLoginCancelled
}
