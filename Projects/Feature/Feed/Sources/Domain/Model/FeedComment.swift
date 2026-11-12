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

    public init(
        commentId: Int,
        nickname: String,
        profileImageUrl: String?,
        content: String,
        createdTime: String,
        isMine: Bool = false
    ) {
        self.commentId = commentId
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.content = content
        self.createdTime = createdTime
        self.isMine = isMine
    }
}
