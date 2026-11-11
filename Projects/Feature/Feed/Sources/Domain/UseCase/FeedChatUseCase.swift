//
//  FeedChatUseCase.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

public struct FeedChatUseCase {
    private let chatRepository: FeedChatRepositoryProtocol

    public init(chatRepository: FeedChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }

    public func fetchRecordDetail(
        groupId: Int,
        recordId: Int,
        size: Int = 20
    ) async throws -> FeedRecordDetailPage {
        try await chatRepository.getRecordDetail(
            groupId: groupId,
            recordId: recordId,
            cursor: nil,
            size: size
        )
    }

    /// 다음 페이지를 이어 붙이며, 이미 가진 기록은 중복으로 추가하지 않습니다.
    public func fetchNextRecordDetail(
        groupId: Int,
        recordId: Int,
        currentPage: FeedRecordDetailPage,
        size: Int = 20
    ) async throws -> FeedRecordDetailPage {
        guard currentPage.hasNext,
              let cursor = currentPage.nextCursor else {
            return currentPage
        }

        let nextPage = try await chatRepository.getRecordDetail(
            groupId: groupId,
            recordId: recordId,
            cursor: cursor,
            size: size
        )
        var recordIDs = Set(currentPage.records.map(\.recordId))
        let newRecords = nextPage.records.filter { recordIDs.insert($0.recordId).inserted }

        return FeedRecordDetailPage(
            records: currentPage.records + newRecords,
            currentIndex: currentPage.currentIndex,
            nextCursor: nextPage.nextCursor,
            hasNext: nextPage.hasNext && nextPage.nextCursor != currentPage.nextCursor
        )
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
}
