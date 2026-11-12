//
//  FeedChatUseCase.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

public struct FeedChatUseCase {
    /// 한 날짜의 피드를 끝까지 받을 때 무한 반복을 막기 위한 최대 요청 횟수입니다.
    private static let maxDayRecordRequests = 10

    private let chatRepository: FeedChatRepositoryProtocol
    private let feedRepository: FeedRepositoryProtocol

    public init(
        chatRepository: FeedChatRepositoryProtocol,
        feedRepository: FeedRepositoryProtocol
    ) {
        self.chatRepository = chatRepository
        self.feedRepository = feedRepository
    }

    /// 해당 날짜에 그룹에 올라온 피드를 모두 받아옵니다.
    public func fetchDayRecords(
        groupId: Int,
        date: String,
        myMemberId: Int?,
        size: Int = 20
    ) async throws -> [FeedRecordDetail] {
        var records: [FeedRecord] = []
        var recordIDs = Set<Int>()
        var cursor: Int?

        for _ in 0..<Self.maxDayRecordRequests {
            let page = try await feedRepository.getRecords(
                groupId: groupId,
                date: date,
                cursor: cursor,
                size: size
            )
            records += page.records.filter { recordIDs.insert($0.recordId).inserted }

            guard page.hasNext,
                  let nextCursor = page.nextCursor,
                  nextCursor != cursor else {
                break
            }
            cursor = nextCursor
        }

        return records.map { FeedRecordDetail(record: $0, myMemberId: myMemberId) }
    }

    public func fetchComments(
        groupId: Int,
        recordId: Int,
        size: Int = 50
    ) async throws -> FeedCommentPage {
        try await chatRepository.getComments(
            groupId: groupId,
            recordId: recordId,
            cursor: nil,
            size: size
        )
    }

    public func sendComment(
        groupId: Int,
        recordId: Int,
        content: String
    ) async throws {
        try await chatRepository.postComment(
            groupId: groupId,
            recordId: recordId,
            content: content
        )
    }

    public func deleteComment(
        groupId: Int,
        recordId: Int,
        commentId: Int
    ) async throws {
        try await chatRepository.deleteComment(
            groupId: groupId,
            recordId: recordId,
            commentId: commentId
        )
    }
}
