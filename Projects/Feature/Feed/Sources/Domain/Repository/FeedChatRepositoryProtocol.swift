//
//  FeedChatRepositoryProtocol.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

public protocol FeedChatRepositoryProtocol {
    func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedCommentPage

    func postComment(
        groupId: Int,
        recordId: Int,
        content: String
    ) async throws

    func deleteComment(
        groupId: Int,
        recordId: Int,
        commentId: Int
    ) async throws
}
