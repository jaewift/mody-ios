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
            content: content ?? "",
            createdTime: Self.timeText(from: createdAt)
        )
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
