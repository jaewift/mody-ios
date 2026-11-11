//
//  FeedChatTests.swift
//  FeedTests
//
//  Created by Jaewift on 11/11/26.
//

import Foundation
import XCTest
import CommonDomain
import CoreAuthInterface
import FeedInterface
@testable import Feed

final class FeedChatTests: XCTestCase {
    func testCommentResponseMapsCreatedAtToHourMinute() throws {
        let data = Data("""
        {
          "comments": [
            {
              "commentId": 1,
              "nickname": "예은",
              "content": "파이팅",
              "createdAt": "2026-11-11T13:50:12.123",
              "isMine": false
            },
            { "content": "commentId 없음" }
          ],
          "nextCursor": null,
          "hasNext": false
        }
        """.utf8)

        let page = try JSONDecoder().decode(FeedCommentListResponse.self, from: data).toDomain()

        XCTAssertEqual(page.comments.count, 1)
        XCTAssertEqual(page.comments.first?.createdTime, "13:50")
        XCTAssertEqual(page.comments.first?.nickname, "예은")
    }

    func testRecordDetailResponseTrimsRecordedTimeAndDropsRecordsWithoutImage() throws {
        let data = Data("""
        {
          "totalCount": 2,
          "currentIndex": 1,
          "records": [
            { "recordId": 10, "recordType": "MEAL", "recordedTime": "13:00:00", "menu": "계란", "imageUrl": "a.jpg", "isMine": true },
            { "recordId": 11, "recordType": "EXERCISE", "imageUrl": "  " }
          ],
          "hasNext": false
        }
        """.utf8)

        let page = try JSONDecoder().decode(FeedRecordDetailResponse.self, from: data).toDomain()

        XCTAssertEqual(page.records.map(\.recordId), [10])
        XCTAssertEqual(page.records.first?.recordedTime, "13:00")
        XCTAssertEqual(page.records.first?.isMine, true)
        XCTAssertEqual(page.currentIndex, 1)
    }

    func testInitialPageIndexPrefersRequestedRecordOverServerIndex() {
        let page = makePage(recordIds: [1, 2, 3], currentIndex: 0)

        XCTAssertEqual(FeedChatReactor.initialPageIndex(of: 3, in: page), 2)
    }

    func testInitialPageIndexClampsServerIndexWhenRecordIsMissing() {
        let page = makePage(recordIds: [1, 2], currentIndex: 5)

        XCTAssertEqual(FeedChatReactor.initialPageIndex(of: 99, in: page), 1)
    }

    func testFetchNextRecordDetailAppendsOnlyNewRecords() async throws {
        let repository = FeedChatRepositoryMock(
            nextPage: makePage(recordIds: [2, 3], currentIndex: 0, nextCursor: nil, hasNext: false)
        )
        let useCase = FeedChatUseCase(chatRepository: repository)

        let page = try await useCase.fetchNextRecordDetail(
            groupId: 1,
            recordId: 1,
            currentPage: makePage(recordIds: [1, 2], currentIndex: 0, nextCursor: 20, hasNext: true)
        )

        XCTAssertEqual(page.records.map(\.recordId), [1, 2, 3])
        XCTAssertFalse(page.hasNext)
        XCTAssertEqual(repository.requestedCursor, 20)
    }

    @MainActor
    func testReducerIgnoresCommentsForNonCurrentRecord() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecordPage(makePage(recordIds: [1, 2], currentIndex: 0), initialRecordId: 1)
        )
        state = reactor.reduce(state: state, mutation: .setCurrentPageIndex(1))

        let staleState = reactor.reduce(
            state: state,
            mutation: .setComments([makeComment(id: 1)], recordId: 1)
        )
        let freshState = reactor.reduce(
            state: state,
            mutation: .setComments([makeComment(id: 2)], recordId: 2)
        )

        XCTAssertTrue(staleState.comments.isEmpty)
        XCTAssertEqual(freshState.comments.map(\.commentId), [2])
    }
}

extension FeedChatTests {
    @MainActor
    func testPendingCommentIsShownAfterServerCommentsForCurrentRecordOnly() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecordPage(makePage(recordIds: [1, 2], currentIndex: 0), initialRecordId: 1)
        )
        state = reactor.reduce(state: state, mutation: .setComments([makeComment(id: 1)], recordId: 1))
        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 1, comment: makeComment(id: -10)))
        )
        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 2, comment: makeComment(id: -11)))
        )

        XCTAssertEqual(state.displayedComments.map(\.commentId), [1, -10])
    }

    @MainActor
    func testConfirmedPendingCommentIsReplacedByServerComments() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecordPage(makePage(recordIds: [1], currentIndex: 0), initialRecordId: 1)
        )
        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 1, comment: makeComment(id: -10)))
        )
        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 1, comment: makeComment(id: -11)))
        )
        state = reactor.reduce(state: state, mutation: .confirmPendingComment(commentId: -10))
        state = reactor.reduce(state: state, mutation: .setComments([makeComment(id: 5)], recordId: 1))

        // 저장이 끝난 -10은 서버 목록(5)으로 대체되고, 아직 전송 중인 -11은 유지됩니다.
        XCTAssertEqual(state.displayedComments.map(\.commentId), [5, -11])
    }

    @MainActor
    func testFailedPendingCommentIsRemoved() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecordPage(makePage(recordIds: [1], currentIndex: 0), initialRecordId: 1)
        )
        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 1, comment: makeComment(id: -10)))
        )
        state = reactor.reduce(state: state, mutation: .removePendingComment(commentId: -10))

        XCTAssertTrue(state.displayedComments.isEmpty)
    }
}

private extension FeedChatTests {
    @MainActor
    func makeReactor() -> FeedChatReactor {
        FeedChatReactor(
            router: FeedChatRouterMock(),
            groupId: 1,
            recordId: 1,
            chatUseCase: FeedChatUseCase(chatRepository: FeedChatRepositoryMock()),
            feedUseCase: FeedUseCase(feedRepository: FeedRepositoryDummy()),
            authUseCase: FeedChatAuthUseCaseMock(),
            output: { _ in }
        )
    }

    func makePage(
        recordIds: [Int],
        currentIndex: Int,
        nextCursor: Int? = nil,
        hasNext: Bool = false
    ) -> FeedRecordDetailPage {
        FeedRecordDetailPage(
            records: recordIds.map(makeRecord(id:)),
            currentIndex: currentIndex,
            nextCursor: nextCursor,
            hasNext: hasNext
        )
    }

    func makeRecord(id: Int) -> FeedRecordDetail {
        FeedRecordDetail(
            recordId: id,
            recordType: .meal,
            nickname: "user\(id)",
            profileImageUrl: nil,
            recordedTime: "13:00",
            menu: "계란",
            exerciseDurationMinutes: 0,
            exerciseName: "",
            imageUrl: "https://example.com/\(id).jpg",
            imageCropRegion: nil,
            isMine: false
        )
    }

    func makeComment(id: Int) -> FeedComment {
        FeedComment(
            commentId: id,
            nickname: "user\(id)",
            profileImageUrl: nil,
            content: "댓글",
            createdTime: "13:00"
        )
    }
}

private final class FeedChatRepositoryMock: FeedChatRepositoryProtocol {
    private let nextPage: FeedRecordDetailPage?
    private(set) var requestedCursor: Int?

    init(nextPage: FeedRecordDetailPage? = nil) {
        self.nextPage = nextPage
    }

    func getRecordDetail(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedRecordDetailPage {
        requestedCursor = cursor
        return nextPage ?? FeedRecordDetailPage(
            records: [],
            currentIndex: 0,
            nextCursor: nil,
            hasNext: false
        )
    }

    func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedCommentPage {
        FeedCommentPage(comments: [], nextCursor: nil, hasNext: false)
    }

    func postComment(groupId: Int, recordId: Int, content: String) async throws {}
}

private struct FeedRepositoryDummy: FeedRepositoryProtocol {
    func getActivityCalendar(groupId: Int, baseDate: String) async throws -> FeedActivityCalendarModel {
        throw URLError(.unsupportedURL)
    }

    func getRecords(groupId: Int, date: String, cursor: Int?, size: Int) async throws -> FeedRecordPage {
        throw URLError(.unsupportedURL)
    }

    func postRecord(_ request: FeedRecordCreateRequest) async throws {}
    func postRecordReport(groupId: Int, recordId: Int) async throws {}
    func deleteRecord(recordId: Int) async throws {}
}

@MainActor
private final class FeedChatRouterMock: FeedChatRouter {
    func route(from route: FeedChatRoute) {}
}

private struct FeedChatAuthUseCaseMock: AuthUseCaseProtocol {
    func signIn(
        loginType: SocialLoginType,
        accessToken: String
    ) async throws -> AuthSession {
        throw CancellationError()
    }

    func getUserInfo(needUpdateKeyChain: Bool) async throws -> UserInfo {
        UserInfo(
            memberId: 1,
            nickname: "테스터",
            profileImageUrl: nil,
            daysTogether: 1,
            personalInfoCompleted: true,
            groupOnboardingCompleted: true,
            mainAccessible: true
        )
    }

    func logout() async throws {}

    func deleteAccount() async throws {}
}
