//
//  GoogleAnalyticsEvent.swift
//  CoreAnalyticsInterface
//
//  Created by Jaewift on 10/31/26.
//

/// GA4 이벤트 명세서 기준 이벤트. 파라미터 값은 명세에 따라 모두 문자열로 보냅니다.
public struct GoogleAnalyticsEvent: Equatable {
    public let name: String
    public let parameters: [String: String]

    public init(
        name: String,
        parameters: [String: String] = [:]
    ) {
        self.name = name
        self.parameters = parameters
    }
}

public extension GoogleAnalyticsEvent {
    static func screenView(
        screenName: String,
        parameters: [String: String] = [:]
    ) -> GoogleAnalyticsEvent {
        var parameters = parameters
        parameters[ParameterKey.screenName] = screenName

        return GoogleAnalyticsEvent(
            name: EventName.screenView,
            parameters: parameters
        )
    }
}

private extension GoogleAnalyticsEvent {
    enum EventName {
        static let screenView = "screen_view"
    }

    enum ParameterKey {
        static let screenName = "screen_name"
    }
}
