//
//  FeedChatRepository.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CommonDomain
import CoreNetworkInterface

public struct FeedChatRepository: FeedChatRepositoryProtocol {
    private let network: CoreNetworkProtocol

    public init(network: CoreNetworkProtocol) {
        self.network = network
    }

    public func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedCommentPage {
        let response: CoreNetworkResponse<FeedCommentListResponse> = try await network.request(
            FeedChatEndpoint.getComments(
                groupId: groupId,
                recordId: recordId,
                cursor: cursor,
                size: size
            )
        )

        guard let result = response.result else {
            throw NetworkError.invalidResponse
        }

        return result.toDomain()
    }

    public func postComment(
        groupId: Int,
        recordId: Int,
        content: String
    ) async throws {
        let response: CoreNetworkResponse<CoreNetworkEmptyResponse> = try await network.request(
            FeedChatEndpoint.postComment(
                groupId: groupId,
                recordId: recordId,
                body: FeedCommentCreateBody(content: content)
            )
        )

        guard response.isSuccess != false else {
            throw NetworkError.invalidResponse
        }
    }

    public func deleteComment(
        groupId: Int,
        recordId: Int,
        commentId: Int
    ) async throws {
        let response: CoreNetworkResponse<CoreNetworkEmptyResponse> = try await network.request(
            FeedChatEndpoint.deleteComment(
                groupId: groupId,
                recordId: recordId,
                commentId: commentId
            )
        )

        guard response.isSuccess != false else {
            throw NetworkError.invalidResponse
        }
    }
}
