//
//  FeedDemoChatMockRepository.swift
//  FeedDemo
//
//  Created by Jaewift on 11/11/26.
//

import Feed
import Foundation

actor FeedDemoChatMockRepository: FeedChatRepositoryProtocol {
    private var commentsByRecordId: [Int: [FeedComment]] = [:]
    private var nextCommentId = 1

    func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedCommentPage {
        FeedCommentPage(
            comments: commentsByRecordId[recordId] ?? Self.defaultComments,
            nextCursor: nil,
            hasNext: false
        )
    }

    func postComment(
        groupId: Int,
        recordId: Int,
        content: String
    ) async throws {
        let comment = FeedComment(
            commentId: 1_000 + nextCommentId,
            nickname: "나",
            profileImageUrl: nil,
            content: content,
            createdTime: Self.currentTimeText(),
            isMine: true
        )
        nextCommentId += 1
        commentsByRecordId[recordId, default: Self.defaultComments].append(comment)
    }

    func deleteComment(
        groupId: Int,
        recordId: Int,
        commentId: Int
    ) async throws {
        commentsByRecordId[recordId, default: Self.defaultComments].removeAll { $0.commentId == commentId }
    }
}

private extension FeedDemoChatMockRepository {
    static let defaultComments = [
        FeedComment(
            commentId: 1,
            nickname: "예은",
            profileImageUrl: nil,
            content: "계란 3알로 오늘 어떻게 버텨요?? ㅠㅠㅠ\n보기만 해도 배가 고프네요 ㅠㅠ",
            createdTime: "13:50"
        ),
        FeedComment(
            commentId: 2,
            nickname: "재규",
            profileImageUrl: nil,
            content: "파이팅 합시다!!!!",
            createdTime: "13:54"
        ),
        FeedComment(
            commentId: 3,
            nickname: "도윤",
            profileImageUrl: nil,
            content: "벌써 배가 고파요",
            createdTime: "13:54"
        )
    ]

    static func currentTimeText() -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
