//
//  FeedCommentEmoji.swift
//  Feed
//
//  Created by Jaewift on 11/16/26.
//

/// 텍스트 없이 바로 보내는 응원 이모지입니다. `rawValue`는 서버의 `emojiId`와 같습니다.
public enum FeedCommentEmoji: String, CaseIterable, Equatable {
    case clap
    case medal
    case fire
    case heart
    case run
}
