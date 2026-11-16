//
//  FeedComment.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

public struct FeedCommentPage: Equatable {
    public let comments: [FeedComment]
    public let nextCursor: Int?
    public let hasNext: Bool

    public init(
        comments: [FeedComment],
        nextCursor: Int?,
        hasNext: Bool
    ) {
        self.comments = comments
        self.nextCursor = nextCursor
        self.hasNext = hasNext
    }
}

public struct FeedComment: Equatable {
    public let commentId: Int
    public let nickname: String
    public let profileImageUrl: String?
    public let content: String
    /// `HH:mm`
    public let createdTime: String
    public let isMine: Bool
    /// 이모지 댓글이면 값이 있고, 이때 `content`는 비어 있습니다.
    public let emoji: FeedCommentEmoji?

    public init(
        commentId: Int,
        nickname: String,
        profileImageUrl: String?,
        content: String,
        createdTime: String,
        isMine: Bool = false,
        emoji: FeedCommentEmoji? = nil
    ) {
        self.commentId = commentId
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.content = content
        self.createdTime = createdTime
        self.isMine = isMine
        self.emoji = emoji
    }
}
