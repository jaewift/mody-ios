//
//  FeedChatReactor.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import Foundation
import CommonDomain
import CoreAuthInterface
import FeedInterface
import ReactorKit
import Util

public final class FeedChatReactor: Reactor {
    public let initialState: State
    private weak var router: FeedChatRouter?
    private let chatUseCase: FeedChatUseCase
    private let feedUseCase: FeedUseCase
    private let authUseCase: AuthUseCaseProtocol
    private let output: @MainActor (FeedChatOutput) -> Void

    public enum Alert: Equatable {
        case deleteConfirmation(recordId: Int)
        case reportConfirmation(recordId: Int)
        case reportSucceeded
        case failure(NetworkError)
    }

    /// 서버 저장 전에 먼저 화면에 보여주는 내 댓글입니다.
    public struct PendingComment: Equatable {
        let recordId: Int
        let comment: FeedComment
        /// 서버 저장이 끝났지만 아직 목록을 다시 받아오기 전인 상태입니다.
        var isConfirmed = false

        init(recordId: Int, comment: FeedComment, isConfirmed: Bool = false) {
            self.recordId = recordId
            self.comment = comment
            self.isConfirmed = isConfirmed
        }
    }

    public struct State {
        let groupId: Int
        let initialRecordId: Int
        var recordPage: FeedRecordDetailPage?
        var currentPageIndex = 0
        var comments: [FeedComment] = []
        var pendingComments: [PendingComment] = []
        var commentText = ""
        var myProfile: UserInfo?
        var isInitialLoading = false
        var isNextRecordPageLoading = false
        var isRecordMenuLoading = false
        var alert: Alert?

        var records: [FeedRecordDetail] { recordPage?.records ?? [] }

        var currentRecord: FeedRecordDetail? {
            records.indices.contains(currentPageIndex) ? records[currentPageIndex] : nil
        }

        /// 서버 댓글 뒤에 전송 중인 내 댓글을 이어 붙인 목록입니다.
        var displayedComments: [FeedComment] {
            guard let recordId = currentRecord?.recordId else { return [] }
            return comments + pendingComments
                .filter { $0.recordId == recordId }
                .map(\.comment)
        }

        var canSendComment: Bool {
            currentRecord != nil
                && !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public enum Action {
        case viewDidLoad
        case didTapBackButton
        case didChangePage(Int)
        case didChangeCommentText(String)
        case didTapEmoji(String)
        case didTapSendComment
        case didTapRecordMenu(FeedRecordMenu)
        case didConfirmAlert
        case didDismissAlert
    }

    public enum Mutation {
        case setInitialLoading(Bool)
        case setRecordPage(FeedRecordDetailPage, initialRecordId: Int?)
        case setNextRecordPageLoading(Bool)
        case setCurrentPageIndex(Int)
        case setComments([FeedComment], recordId: Int)
        case setCommentText(String)
        case setMyProfile(UserInfo)
        case appendPendingComment(PendingComment)
        case confirmPendingComment(commentId: Int)
        case removePendingComment(commentId: Int)
        case setRecordMenuLoading(Bool)
        case setAlert(Alert?)
    }

    public init(
        router: FeedChatRouter,
        groupId: Int,
        recordId: Int,
        chatUseCase: FeedChatUseCase,
        feedUseCase: FeedUseCase,
        authUseCase: AuthUseCaseProtocol,
        output: @escaping @MainActor (FeedChatOutput) -> Void
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.feedUseCase = feedUseCase
        self.authUseCase = authUseCase
        self.output = output
        self.initialState = State(
            groupId: groupId,
            initialRecordId: recordId
        )
    }

    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .merge([
                fetchRecordDetail(),
                fetchMyProfile()
            ])
        case .didTapBackButton:
            return route(.back)
        case let .didChangePage(index):
            guard index != currentState.currentPageIndex,
                  currentState.records.indices.contains(index) else {
                return .empty()
            }
            return .concat([
                .just(.setCurrentPageIndex(index)),
                fetchComments(recordId: currentState.records[index].recordId),
                fetchNextRecordPageIfNeeded(visibleIndex: index)
            ])
        case let .didChangeCommentText(text):
            return .just(.setCommentText(text))
        case let .didTapEmoji(emoji):
            // 이모지는 입력 중인 글과 별개로 바로 댓글로 남깁니다.
            guard let recordId = currentState.currentRecord?.recordId else { return .empty() }
            return sendComment(recordId: recordId, content: emoji, restoresTextOnFailure: false)
        case .didTapSendComment:
            guard currentState.canSendComment,
                  let recordId = currentState.currentRecord?.recordId else {
                return .empty()
            }
            return .concat([
                .just(.setCommentText("")),
                sendComment(
                    recordId: recordId,
                    content: currentState.commentText,
                    restoresTextOnFailure: true
                )
            ])
        case let .didTapRecordMenu(menu):
            guard let recordId = currentState.currentRecord?.recordId else { return .empty() }
            switch menu {
            case .delete:
                return .just(.setAlert(.deleteConfirmation(recordId: recordId)))
            case .report:
                return .just(.setAlert(.reportConfirmation(recordId: recordId)))
            }
        case .didConfirmAlert:
            let alert = currentState.alert
            let dismissAlert = Observable<Mutation>.just(.setAlert(nil))

            switch alert {
            case let .deleteConfirmation(recordId):
                return .concat([dismissAlert, deleteRecord(recordId: recordId)])
            case let .reportConfirmation(recordId):
                return .concat([dismissAlert, reportRecord(recordId: recordId)])
            case .reportSucceeded, .failure, .none:
                return dismissAlert
            }
        case .didDismissAlert:
            return .just(.setAlert(nil))
        }
    }

    public func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case let .setInitialLoading(isLoading):
            newState.isInitialLoading = isLoading
        case let .setRecordPage(page, initialRecordId):
            newState.recordPage = page
            if let initialRecordId {
                newState.currentPageIndex = Self.initialPageIndex(
                    of: initialRecordId,
                    in: page
                )
            }
        case let .setNextRecordPageLoading(isLoading):
            newState.isNextRecordPageLoading = isLoading
        case let .setCurrentPageIndex(index):
            newState.currentPageIndex = index
            newState.comments = []
        case let .setComments(comments, recordId):
            // 응답이 늦게 도착해 다른 슬라이드의 댓글로 덮어쓰지 않도록 현재 기록과 비교합니다.
            guard newState.currentRecord?.recordId == recordId else { break }
            newState.comments = comments
            // 저장이 끝난 댓글은 방금 받은 서버 목록에 포함되어 있으므로 임시 댓글을 지웁니다.
            newState.pendingComments.removeAll { $0.recordId == recordId && $0.isConfirmed }
        case let .setCommentText(text):
            newState.commentText = text
        case let .setMyProfile(profile):
            newState.myProfile = profile
        case let .appendPendingComment(pendingComment):
            newState.pendingComments.append(pendingComment)
        case let .confirmPendingComment(commentId):
            if let index = newState.pendingComments.firstIndex(where: { $0.comment.commentId == commentId }) {
                newState.pendingComments[index].isConfirmed = true
            }
        case let .removePendingComment(commentId):
            newState.pendingComments.removeAll { $0.comment.commentId == commentId }
        case let .setRecordMenuLoading(isLoading):
            newState.isRecordMenuLoading = isLoading
        case let .setAlert(alert):
            newState.alert = alert
        }

        return newState
    }
}

extension FeedChatReactor {
    static func initialPageIndex(
        of recordId: Int,
        in page: FeedRecordDetailPage
    ) -> Int {
        if let index = page.records.firstIndex(where: { $0.recordId == recordId }) {
            return index
        }

        return min(max(page.currentIndex, 0), max(page.records.count - 1, 0))
    }
}

private extension FeedChatReactor {
    func fetchRecordDetail() -> Observable<Mutation> {
        let groupId = currentState.groupId
        let recordId = currentState.initialRecordId

        let fetch = asyncObservable { [weak self] () -> Observable<Mutation>? in
            guard let self else { return nil }

            do {
                let page = try await self.chatUseCase.fetchRecordDetail(
                    groupId: groupId,
                    recordId: recordId
                )
                let index = Self.initialPageIndex(of: recordId, in: page)
                let commentRecordId = page.records.indices.contains(index)
                    ? page.records[index].recordId
                    : nil

                return .concat([
                    .just(.setRecordPage(page, initialRecordId: recordId)),
                    commentRecordId.map { self.fetchComments(recordId: $0) } ?? .empty()
                ])
            } catch {
                return .just(.setAlert(.failure(error as? NetworkError ?? .unknown)))
            }
        }
        .flatMap { $0 }

        return .concat([
            .just(.setInitialLoading(true)),
            fetch,
            .just(.setInitialLoading(false))
        ])
    }

    func fetchNextRecordPageIfNeeded(visibleIndex: Int) -> Observable<Mutation> {
        guard let page = currentState.recordPage,
              page.hasNext,
              !currentState.isNextRecordPageLoading,
              visibleIndex >= page.records.count - 2 else {
            return .empty()
        }

        let groupId = currentState.groupId
        let recordId = currentState.initialRecordId
        let fetch = asyncObservable { [weak self] () -> Mutation? in
            guard let self,
                  let nextPage = try? await self.chatUseCase.fetchNextRecordDetail(
                    groupId: groupId,
                    recordId: recordId,
                    currentPage: page
                  ) else {
                return nil
            }

            return .setRecordPage(nextPage, initialRecordId: nil)
        }

        return .concat([
            .just(.setNextRecordPageLoading(true)),
            fetch,
            .just(.setNextRecordPageLoading(false))
        ])
    }

    func fetchComments(recordId: Int) -> Observable<Mutation> {
        let groupId = currentState.groupId

        return asyncObservable { [weak self] () -> Mutation? in
            guard let self,
                  let page = try? await self.chatUseCase.fetchComments(
                    groupId: groupId,
                    recordId: recordId
                  ) else {
                return nil
            }

            return .setComments(page.comments, recordId: recordId)
        }
    }

    func fetchMyProfile() -> Observable<Mutation> {
        asyncObservable { [weak self] () -> Mutation? in
            guard let self,
                  let profile = try? await self.authUseCase.getUserInfo(needUpdateKeyChain: false) else {
                return nil
            }

            return .setMyProfile(profile)
        }
    }

    /// 서버 응답을 기다리지 않고 내 댓글을 먼저 보여준 뒤, 저장 결과에 맞춰 목록을 정리합니다.
    func sendComment(
        recordId: Int,
        content: String,
        restoresTextOnFailure: Bool
    ) -> Observable<Mutation> {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return .empty() }

        let groupId = currentState.groupId
        let pendingComment = makePendingComment(recordId: recordId, content: trimmedContent)
        let pendingCommentId = pendingComment.comment.commentId

        let send = asyncObservable { [weak self] () -> Observable<Mutation>? in
            guard let self else { return nil }

            do {
                try await self.chatUseCase.sendComment(
                    groupId: groupId,
                    recordId: recordId,
                    content: trimmedContent
                )
                return .concat([
                    .just(.confirmPendingComment(commentId: pendingCommentId)),
                    self.fetchComments(recordId: recordId)
                ])
            } catch {
                var mutations: [Mutation] = [.removePendingComment(commentId: pendingCommentId)]
                if restoresTextOnFailure, self.currentState.commentText.isEmpty {
                    mutations.append(.setCommentText(content))
                }
                mutations.append(.setAlert(.failure(error as? NetworkError ?? .unknown)))
                return .from(mutations)
            }
        }
        .flatMap { $0 }

        return .concat([
            .just(.appendPendingComment(pendingComment)),
            send
        ])
    }

    func makePendingComment(recordId: Int, content: String) -> PendingComment {
        let profile = currentState.myProfile
        // 서버 commentId와 겹치지 않도록 음수 임시 id를 사용합니다.
        let temporaryId = -Int(Date().timeIntervalSince1970 * 1_000) - currentState.pendingComments.count

        return PendingComment(
            recordId: recordId,
            comment: FeedComment(
                commentId: temporaryId,
                nickname: profile?.nickname ?? "",
                profileImageUrl: profile?.profileImageUrl,
                content: content,
                createdTime: Date().toString(format: .custom("HH:mm"))
            )
        )
    }

    func deleteRecord(recordId: Int) -> Observable<Mutation> {
        let delete = asyncObservable { [weak self] () -> Observable<Mutation>? in
            guard let self else { return nil }

            do {
                try await self.feedUseCase.removeRecord(recordId: recordId)
                self.output(.recordDeleted)
                return .empty()
            } catch {
                return .just(.setAlert(.failure(error as? NetworkError ?? .unknown)))
            }
        }
        .flatMap { $0 }

        return .concat([
            .just(.setRecordMenuLoading(true)),
            delete,
            .just(.setRecordMenuLoading(false))
        ])
    }

    func reportRecord(recordId: Int) -> Observable<Mutation> {
        let groupId = currentState.groupId

        let report = asyncObservable { [weak self] () -> Mutation? in
            guard let self else { return nil }

            do {
                try await self.feedUseCase.reportRecord(groupId: groupId, recordId: recordId)
                return .setAlert(.reportSucceeded)
            } catch {
                return .setAlert(.failure(error as? NetworkError ?? .unknown))
            }
        }

        return .concat([
            .just(.setRecordMenuLoading(true)),
            report,
            .just(.setRecordMenuLoading(false))
        ])
    }

    func route(_ route: FeedChatRoute) -> Observable<Mutation> {
        .deferred { [weak router] in
            Task { @MainActor in
                router?.route(from: route)
            }
            return .empty()
        }
    }

    func asyncObservable<Element>(
        _ operation: @escaping @MainActor () async -> Element?
    ) -> Observable<Element> {
        Observable.create { observer in
            let task = Task { @MainActor in
                if let element = await operation() {
                    observer.onNext(element)
                }
                observer.onCompleted()
            }

            return Disposables.create { task.cancel() }
        }
        .observe(on: MainScheduler.instance)
    }
}
