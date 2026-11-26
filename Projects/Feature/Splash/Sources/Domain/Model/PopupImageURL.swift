//
//  PopupImageURL.swift
//  Splash
//

import Foundation

/// Remote Config로 내려오는 팝업 일러스트 URL을 검증합니다.
enum PopupImageURL {
    /// 공백을 제거한 뒤 https 스킴과 호스트가 있는 URL만 반환합니다.
    static func validated(_ urlString: String?) -> URL? {
        guard let trimmedURLString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: trimmedURLString),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false else {
            return nil
        }

        return url
    }
}
