//
//  FeedChatEndpoint.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreNetworkInterface

enum FeedChatEndpoint {
    static func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) -> CoreNetworkEndpoint {
        var queryParameters = ["size": String(size)]

        if let cursor {
            queryParameters["cursor"] = String(cursor)
        }

        return CoreNetworkEndpoint(
            path: "api/v1/groups/\(groupId)/records/\(recordId)/comments",
            method: .GET,
            queryParameters: queryParameters
        )
    }

    static func postComment(
        groupId: Int,
        recordId: Int,
        body: FeedCommentCreateBody
    ) -> CoreNetworkEndpoint {
        CoreNetworkEndpoint(
            path: "api/v1/groups/\(groupId)/records/\(recordId)/comments",
            method: .POST,
            bodyParameters: body
        )
    }
}
