//
//  ModyGroupGoogleAnalyticsEvent.swift
//  ModyGroup
//
//  Created by Jaewift on 10/31/26.
//

import CoreAnalyticsInterface
import ModyGroupInterface

enum ModyGroupGoogleAnalyticsEvent {
    enum ShareMethod: String {
        case kakao
        case copy
    }

    static func groupShareClicked(method: ShareMethod) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_share_click",
            parameters: ["share_method": method.rawValue]
        )
    }

    static let groupCreateFinished = GoogleAnalyticsEvent(name: "group_create_finish")

    static func groupJoinScreenView(entrySource: ModyGroupEntrySource) -> GoogleAnalyticsEvent {
        .screenView(.groupJoin, parameters: entrySourceParameter(entrySource))
    }

    static let groupCreateScreenView = GoogleAnalyticsEvent.screenView(.groupCreate)

    static let codeShareScreenView = GoogleAnalyticsEvent.screenView(.codeShare)

    static func groupJoined(entrySource: ModyGroupEntrySource) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "join_group",
            parameters: entrySourceParameter(entrySource)
        )
    }

    /// 그룹 참여 실패 사유. 서버 실패 코드 기준입니다.
    enum JoinFailReason: String {
        /// GROUP301: 존재하지 않는 코드
        case invalidCode = "invalid_code"
        /// GROUP304: 인원이 꽉 찬 그룹
        case groupFull = "group_full"
        /// 그 밖의 서버·네트워크 오류
        case error
    }

    static func groupJoinFailed(
        reason: JoinFailReason,
        entrySource: ModyGroupEntrySource
    ) -> GoogleAnalyticsEvent {
        var parameters = entrySourceParameter(entrySource)
        parameters["fail_reason"] = reason.rawValue
        return GoogleAnalyticsEvent(name: "group_join_fail", parameters: parameters)
    }

    static func groupCreateClicked(entrySource: ModyGroupEntrySource) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_create_click",
            parameters: entrySourceParameter(entrySource)
        )
    }

    static func groupCreateSucceeded(entrySource: ModyGroupEntrySource) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: "group_create_success",
            parameters: entrySourceParameter(entrySource)
        )
    }
}

private extension ModyGroupGoogleAnalyticsEvent {
    static func entrySourceParameter(_ entrySource: ModyGroupEntrySource) -> [String: String] {
        ["entry_source": entrySource.rawValue]
    }
}
