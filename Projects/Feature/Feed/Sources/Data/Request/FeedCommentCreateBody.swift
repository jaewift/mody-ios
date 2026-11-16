//
//  FeedCommentCreateBody.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

/// 이모지 댓글은 `content`를 비우고 `emojiId`만 보냅니다. 일반 댓글은 `emojiId`를 생략합니다.
struct FeedCommentCreateBody: Encodable, Equatable {
    let content: String
    let emojiId: String?
}
