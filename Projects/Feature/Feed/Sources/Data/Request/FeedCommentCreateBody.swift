//
//  FeedCommentCreateBody.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

/// 이모지는 `:mody-id:` 토큰으로 `content` 안에 넣어 보냅니다.
struct FeedCommentCreateBody: Encodable, Equatable {
    let content: String
}
