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
              "isMine": true
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
        XCTAssertEqual(page.comments.first?.isMine, true)
    }

    func testInitialPageIndexFindsRequestedRecord() {
        XCTAssertEqual(FeedChatReactor.initialPageIndex(of: 3, in: makeRecords(ids: [1, 2, 3])), 2)
    }

    func testInitialPageIndexFallsBackToFirstPageWhenRecordIsMissing() {
        XCTAssertEqual(FeedChatReactor.initialPageIndex(of: 99, in: makeRecords(ids: [1, 2])), 0)
    }

    func testFetchDayRecordsLoadsAllPagesAndMarksMyRecords() async throws {
        let feedRepository = FeedRepositoryStub(pages: [
            nil: FeedRecordPage(
                records: [makeFeedRecord(id: 1, memberId: 7), makeFeedRecord(id: 2, memberId: 8)],
                nextCursor: 20,
                hasNext: true
            ),
            20: FeedRecordPage(
                records: [makeFeedRecord(id: 2, memberId: 8), makeFeedRecord(id: 3, memberId: 9)],
                nextCursor: nil,
                hasNext: false
            )
        ])
        let useCase = FeedChatUseCase(
            chatRepository: FeedChatRepositoryMock(),
            feedRepository: feedRepository
        )

        let records = try await useCase.fetchDayRecords(groupId: 1, date: "2026-11-11", myMemberId: 8)

        XCTAssertEqual(records.map(\.recordId), [1, 2, 3])
        XCTAssertEqual(records.map(\.isMine), [false, true, false])
    }

    @MainActor
    func testReducerIgnoresCommentsForNonCurrentRecord() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecords(makeRecords(ids: [1, 2]))
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

    @MainActor
    func testDeletingCommentIsHiddenAndRestoredOnFailure() {
        let reactor = makeReactor()
        var state = reactor.reduce(state: reactor.initialState, mutation: .setRecords(makeRecords(ids: [1])))
        state = reactor.reduce(
            state: state,
            mutation: .setComments([makeComment(id: 1), makeComment(id: 2)], recordId: 1)
        )

        let deletingState = reactor.reduce(
            state: state,
            mutation: .setCommentDeleting(commentId: 2, isDeleting: true)
        )
        XCTAssertEqual(deletingState.displayedComments.map(\.commentId), [1])

        let restoredState = reactor.reduce(
            state: deletingState,
            mutation: .setCommentDeleting(commentId: 2, isDeleting: false)
        )
        XCTAssertEqual(restoredState.displayedComments.map(\.commentId), [1, 2])
    }

    @MainActor
    func testDeletedCommentIsRemovedFromCache() {
        let reactor = makeReactor()
        var state = reactor.reduce(state: reactor.initialState, mutation: .setRecords(makeRecords(ids: [1])))
        state = reactor.reduce(state: state, mutation: .setComments([makeComment(id: 1)], recordId: 1))
        state = reactor.reduce(state: state, mutation: .setCommentDeleting(commentId: 1, isDeleting: true))
        state = reactor.reduce(state: state, mutation: .removeComment(commentId: 1, recordId: 1))

        XCTAssertTrue(state.comments.isEmpty)
        XCTAssertTrue(state.deletingCommentIds.isEmpty)
        XCTAssertTrue(state.isCommentEmpty)
    }

    @MainActor
    func testCommentEmptyStateAppearsOnlyAfterCommentsAreLoaded() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecords(makeRecords(ids: [1]))
        )
        XCTAssertFalse(state.isCommentEmpty)

        state = reactor.reduce(state: state, mutation: .setComments([], recordId: 1))
        XCTAssertTrue(state.isCommentEmpty)

        state = reactor.reduce(
            state: state,
            mutation: .appendPendingComment(.init(recordId: 1, comment: makeComment(id: -10)))
        )
        XCTAssertFalse(state.isCommentEmpty)
    }

    @MainActor
    func testReturningToPreviousPageShowsCachedComments() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecords(makeRecords(ids: [1, 2]))
        )
        state = reactor.reduce(state: state, mutation: .setComments([makeComment(id: 1)], recordId: 1))
        state = reactor.reduce(state: state, mutation: .setCurrentPageIndex(1))
        XCTAssertTrue(state.comments.isEmpty)

        state = reactor.reduce(state: state, mutation: .setCurrentPageIndex(0))
        XCTAssertEqual(state.comments.map(\.commentId), [1])
    }
}

extension FeedChatTests {
    @MainActor
    func testPendingCommentIsShownAfterServerCommentsForCurrentRecordOnly() {
        let reactor = makeReactor()
        var state = reactor.reduce(
            state: reactor.initialState,
            mutation: .setRecords(makeRecords(ids: [1, 2]))
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
            mutation: .setRecords(makeRecords(ids: [1]))
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
            mutation: .setRecords(makeRecords(ids: [1]))
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
            date: "2026-11-11",
            recordId: 1,
            chatUseCase: FeedChatUseCase(
                chatRepository: FeedChatRepositoryMock(),
                feedRepository: FeedRepositoryStub()
            ),
            feedUseCase: FeedUseCase(feedRepository: FeedRepositoryStub()),
            authUseCase: FeedChatAuthUseCaseMock(),
            output: { _ in }
        )
    }

    func makeRecords(ids: [Int]) -> [FeedRecordDetail] {
        ids.map(makeRecord(id:))
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

    func makeFeedRecord(id: Int, memberId: Int) -> FeedRecord {
        FeedRecord(
            recordId: id,
            recordType: .meal,
            memberId: memberId,
            nickname: "user\(id)",
            profileImageUrl: nil,
            recordedTime: "13:00",
            menu: "계란",
            exerciseDurationMinutes: 0,
            exerciseName: "",
            imageUrl: "https://example.com/\(id).jpg",
            imageCropRegion: nil,
            recordingStreakDays: 1
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

private struct FeedChatRepositoryMock: FeedChatRepositoryProtocol {
    func getComments(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedCommentPage {
        FeedCommentPage(comments: [], nextCursor: nil, hasNext: false)
    }

    func postComment(groupId: Int, recordId: Int, content: String) async throws {}
    func deleteComment(groupId: Int, recordId: Int, commentId: Int) async throws {}
}

private struct FeedRepositoryStub: FeedRepositoryProtocol {
    var pages: [Int?: FeedRecordPage] = [:]


    func getActivityCalendar(groupId: Int, baseDate: String) async throws -> FeedActivityCalendarModel {
        throw URLError(.unsupportedURL)
    }

    func getRecords(groupId: Int, date: String, cursor: Int?, size: Int) async throws -> FeedRecordPage {
        guard let page = pages[cursor] else { throw URLError(.unsupportedURL) }
        return page
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
