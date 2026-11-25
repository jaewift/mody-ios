//
//  NoticePopupInfo.swift
//  Splash
//

import Foundation

/// Remote Config `notice_flag`로 내려오는 공지 팝업 정보입니다.
/// 모든 필드는 optional이라 새 필드를 모르는 구버전 앱과도 호환됩니다.
public struct NoticePopupInfo: Decodable, Equatable {
    /// 한 번만 노출할 공지를 구분하는 식별자입니다. 없으면 실행할 때마다 노출합니다.
    public let id: String?
    /// 상단 일러스트 이미지 URL입니다. 있으면 일러스트형 레이아웃으로 노출합니다.
    public let imageURL: String?
    public let title: String?
    public let contents: String?
    public let skipPossible: Bool?

    public init(
        id: String? = nil,
        imageURL: String? = nil,
        title: String? = nil,
        contents: String? = nil,
        skipPossible: Bool? = nil
    ) {
        self.id = id
        self.imageURL = imageURL
        self.title = title
        self.contents = contents
        self.skipPossible = skipPossible
    }

    public var isEmpty: Bool {
        imageURL == nil && title == nil && contents == nil && skipPossible == nil
    }

    /// 확인 후 다시 노출하지 않을 공지의 식별자입니다.
    /// 닫을 수 없는 공지(점검 등)는 매번 노출해야 하므로 `nil`을 반환합니다.
    public var oneTimeID: String? {
        guard skipPossible == true,
              let id = id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !id.isEmpty else {
            return nil
        }

        return id
    }

    /// 일러스트형 레이아웃 여부입니다. 이미지 로드에 실패해도 레이아웃은 유지합니다.
    public var isIllustrated: Bool {
        imageURL != nil
    }

    /// https 스킴의 유효한 이미지 URL만 반환합니다.
    public var validImageURL: URL? {
        guard let trimmedURLString = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: trimmedURLString),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false else {
            return nil
        }

        return url
    }
}
