//
//  FeedCommentListResponse.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import Foundation

struct FeedCommentListResponse: Decodable, Equatable {
    let comments: [FeedCommentResponse]?
    let nextCursor: Int?
    let hasNext: Bool?
}

struct FeedCommentResponse: Decodable, Equatable {
    let commentId: Int?
    let nickname: String?
    let profileImageUrl: String?
    let content: String?
    let createdAt: String?
    let isMine: Bool?
    let emojiId: String?
    let emojiOnly: Bool?
}

extension FeedCommentListResponse {
    func toDomain() -> FeedCommentPage {
        FeedCommentPage(
            comments: (comments ?? []).compactMap { $0.toDomain() },
            nextCursor: nextCursor,
            hasNext: hasNext ?? false
        )
    }
}

private extension FeedCommentResponse {
    func toDomain() -> FeedComment? {
        guard let commentId else { return nil }

        return FeedComment(
            commentId: commentId,
            nickname: nickname ?? "",
            profileImageUrl: profileImageUrl,
            content: displayContent,
            createdTime: Self.timeText(from: createdAt),
            isMine: isMine ?? false,
            emoji: onlyEmoji
        )
    }

    /// `emojiOnly`가 없던 응답도 `content`가 비어 있고 `emojiId`가 있으면 이모지 단독 댓글로 봅니다.
    var isEmojiOnly: Bool {
        emojiOnly ?? ((content ?? "").isEmpty && emojiId != nil)
    }

    var onlyEmoji: FeedCommentEmoji? {
        guard isEmojiOnly else { return nil }
        return emojiId.flatMap(FeedCommentEmoji.init(rawValue:))
    }

    /// 앱이 모르는 이모지 단독 댓글은 토큰을 글자 그대로 보여줍니다.
    var displayContent: String {
        guard isEmojiOnly, onlyEmoji == nil, let emojiId else { return content ?? "" }
        return ":mody-\(emojiId):"
    }

    /// `2026-11-11T13:50:12` 형태의 서버 시각에서 `HH:mm`만 사용합니다.
    static func timeText(from createdAt: String?) -> String {
        guard let createdAt,
              let timeStartIndex = createdAt.firstIndex(of: "T") else {
            return ""
        }

        return String(createdAt[createdAt.index(after: timeStartIndex)...].prefix(5))
    }
}
