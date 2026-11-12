//
//  ModyGroupRoute.swift
//  ModyGroupInterface
//
//  Created by 김동준 on 6/26/26
//

public enum ModyGroupRoute: Equatable {
    case back
    case finish
}

public enum ModyGroupEntryPoint: Equatable {
    case root
    case main
    case groupSettings
}

/// 그룹 참여·생성 화면에 들어온 경로입니다. GA4 `entry_source` 값으로 사용합니다.
public enum ModyGroupEntrySource: String, Equatable {
    /// 회원가입 직후
    case signup
    /// 피드의 그룹 추가
    case feed
    /// 마지막 그룹에서 나간 뒤 다시 참여
    case rejoin
    /// 그룹 없이 앱을 다시 실행하거나 다시 로그인
    case relaunch
}

public enum ModyGroupInitialScreen: Equatable {
    case participate
    case create(needBackButton: Bool)
}

@MainActor
public protocol ModyGroupRouter: AnyObject {
    func route(from route: ModyGroupRoute)
}
