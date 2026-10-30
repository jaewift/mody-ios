//
//  FirebaseAnalyticsService.swift
//  CoreAnalytics
//
//  Created by Jaewift on 10/31/26.
//

import FirebaseAnalytics
import Foundation

public final class FirebaseAnalyticsService {
    public init() {}

    /// DEV 빌드는 DebugView 실행 인자가 있을 때만 수집합니다.
    /// 수집 여부는 기기에 저장되므로 실행할 때마다 다시 설정하고,
    /// 이전 실행에서 저장된 값으로 수집이 시작되지 않도록 `FirebaseApp.configure()`보다 먼저 호출합니다.
    public func configureCollection() {
        #if DEV
        Analytics.setAnalyticsCollectionEnabled(isDebugViewEnabled)
        #endif
    }
}

private extension FirebaseAnalyticsService {
    var isDebugViewEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains(LaunchArgument.debugEnabled)
            || arguments.contains(LaunchArgument.analyticsDebugEnabled)
    }

    enum LaunchArgument {
        static let debugEnabled = "-FIRDebugEnabled"
        static let analyticsDebugEnabled = "-FIRAnalyticsDebugEnabled"
    }
}
