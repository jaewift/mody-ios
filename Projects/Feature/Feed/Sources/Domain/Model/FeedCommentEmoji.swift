//
//  FeedCommentEmoji.swift
//  Feed
//
//  Created by Jaewift on 11/16/26.
//

/// 댓글에 쓰는 응원 이모지입니다. `rawValue`는 서버의 이모지 id와 같습니다.
public enum FeedCommentEmoji: String, CaseIterable, Equatable {
    case clap
    case medal
    case fire
    case heart
    case run

    /// 댓글 `content`에 넣는 `:mody-id:` 토큰입니다.
    public var token: String {
        ":mody-\(rawValue):"
    }
}

/// 댓글 내용을 글자와 이모지 토큰 단위로 나눈 조각입니다.
public enum FeedCommentContentSegment: Equatable {
    case text(String)
    case emoji(FeedCommentEmoji)
}

public enum FeedCommentContentParser {
    /// `:mody-id:` 토큰을 이모지로 나눕니다. 모르는 id의 토큰은 글자 그대로 둡니다.
    public static func segments(from content: String) -> [FeedCommentContentSegment] {
        var segments: [FeedCommentContentSegment] = []
        var pendingText = ""
        var remaining = content[...]

        while let tokenStart = remaining.range(of: tokenPrefix) {
            let idStart = tokenStart.upperBound
            guard let tokenEnd = remaining[idStart...].firstIndex(of: tokenSuffix) else { break }

            if let emoji = FeedCommentEmoji(rawValue: String(remaining[idStart..<tokenEnd])) {
                pendingText += remaining[..<tokenStart.lowerBound]
                if !pendingText.isEmpty {
                    segments.append(.text(pendingText))
                    pendingText = ""
                }
                segments.append(.emoji(emoji))
                remaining = remaining[remaining.index(after: tokenEnd)...]
            } else {
                // 닫는 `:`는 다음 토큰의 시작일 수 있으므로 남겨 둡니다.
                pendingText += remaining[..<tokenEnd]
                remaining = remaining[tokenEnd...]
            }
        }

        pendingText += remaining
        if !pendingText.isEmpty {
            segments.append(.text(pendingText))
        }
        return segments
    }

    /// 내용이 이모지 토큰 하나뿐이면 그 이모지를 돌려줍니다.
    public static func singleEmoji(in content: String) -> FeedCommentEmoji? {
        let segments = segments(from: content)
        guard segments.count == 1, case let .emoji(emoji) = segments[0] else { return nil }
        return emoji
    }

    private static let tokenPrefix = ":mody-"
    private static let tokenSuffix: Character = ":"
}
