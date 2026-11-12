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
        case commentDeleteConfirmation(commentId: Int, recordId: Int)
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
        let date: String
        let initialRecordId: Int
        var records: [FeedRecordDetail] = []
        var currentPageIndex = 0
        /// 슬라이드를 오갈 때 바로 보여줄 수 있도록 기록별 댓글을 보관합니다.
        var commentsByRecordId: [Int: [FeedComment]] = [:]
        var pendingComments: [PendingComment] = []
        /// 삭제 요청 중이라 목록에서 먼저 숨긴 댓글입니다.
        var deletingCommentIds: Set<Int> = []
        var commentText = ""
        var myProfile: UserInfo?
        var isInitialLoading = false
        var isRecordMenuLoading = false
        var alert: Alert?

        var currentRecord: FeedRecordDetail? {
            records.indices.contains(currentPageIndex) ? records[currentPageIndex] : nil
        }

        var comments: [FeedComment] {
            currentRecord.flatMap { commentsByRecordId[$0.recordId] } ?? []
        }

        /// 서버 댓글 뒤에 전송 중인 내 댓글을 이어 붙인 목록입니다.
        var displayedComments: [FeedComment] {
            guard let recordId = currentRecord?.recordId else { return [] }
            return comments.filter { !deletingCommentIds.contains($0.commentId) } + pendingComments
                .filter { $0.recordId == recordId }
                .map(\.comment)
        }

        /// 현재 피드의 댓글을 받아왔는데 보여줄 댓글이 없는 상태입니다.
        var isCommentEmpty: Bool {
            guard let recordId = currentRecord?.recordId,
                  commentsByRecordId[recordId] != nil else {
                return false
            }
            return displayedComments.isEmpty
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
        case didTapDeleteComment(commentId: Int)
        case didTapRecordMenu(FeedRecordMenu)
        case didConfirmAlert
        case didDismissAlert
    }

    public enum Mutation {
        case setInitialLoading(Bool)
        case setRecords([FeedRecordDetail])
        case setCurrentPageIndex(Int)
        case setComments([FeedComment], recordId: Int)
        case setCommentText(String)
        case setMyProfile(UserInfo)
        case appendPendingComment(PendingComment)
        case confirmPendingComment(commentId: Int)
        case removePendingComment(commentId: Int)
        case setCommentDeleting(commentId: Int, isDeleting: Bool)
        case removeComment(commentId: Int, recordId: Int)
        case setRecordMenuLoading(Bool)
        case setAlert(Alert?)
    }

    public init(
        router: FeedChatRouter,
        groupId: Int,
        date: String,
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
            date: date,
            initialRecordId: recordId
        )
    }

    public func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return fetchDayRecords()
        case .didTapBackButton:
            return route(.back)
        case let .didChangePage(index):
            guard index != currentState.currentPageIndex,
                  currentState.records.indices.contains(index) else {
                return .empty()
            }
            return .concat([
                .just(.setCurrentPageIndex(index)),
                fetchComments(recordId: currentState.records[index].recordId)
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
        case let .didTapDeleteComment(commentId):
            // 서버에 저장되기 전인 임시 댓글(음수 id)은 지울 수 없습니다.
            guard commentId > 0,
                  let recordId = currentState.currentRecord?.recordId else {
                return .empty()
            }
            return .just(.setAlert(.commentDeleteConfirmation(commentId: commentId, recordId: recordId)))
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
            case let .commentDeleteConfirmation(commentId, recordId):
                return .concat([dismissAlert, deleteComment(commentId: commentId, recordId: recordId)])
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
        case let .setRecords(records):
            newState.records = records
            newState.currentPageIndex = Self.initialPageIndex(
                of: newState.initialRecordId,
                in: records
            )
        case let .setCurrentPageIndex(index):
            newState.currentPageIndex = index
        case let .setComments(comments, recordId):
            // 기록별로 저장하므로 늦게 도착한 응답이 다른 슬라이드의 댓글을 덮어쓰지 않습니다.
            newState.commentsByRecordId[recordId] = comments
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
        case let .setCommentDeleting(commentId, isDeleting):
            if isDeleting {
                newState.deletingCommentIds.insert(commentId)
            } else {
                newState.deletingCommentIds.remove(commentId)
            }
        case let .removeComment(commentId, recordId):
            newState.commentsByRecordId[recordId]?.removeAll { $0.commentId == commentId }
            newState.deletingCommentIds.remove(commentId)
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
        in records: [FeedRecordDetail]
    ) -> Int {
        records.firstIndex { $0.recordId == recordId } ?? 0
    }
}

private extension FeedChatReactor {
    /// 내 정보로 본인 피드 여부를 판단해야 하므로 프로필을 받은 뒤 그날 피드를 불러옵니다.
    func fetchDayRecords() -> Observable<Mutation> {
        let groupId = currentState.groupId
        let date = currentState.date
        let recordId = currentState.initialRecordId

        let fetch = asyncObservable { [weak self] () -> Observable<Mutation>? in
            guard let self else { return nil }

            let profile = try? await self.authUseCase.getUserInfo(needUpdateKeyChain: false)
            let setProfile: Observable<Mutation> = profile.map { .just(.setMyProfile($0)) } ?? .empty()

            do {
                let records = try await self.chatUseCase.fetchDayRecords(
                    groupId: groupId,
                    date: date,
                    myMemberId: profile?.memberId
                )
                let index = Self.initialPageIndex(of: recordId, in: records)
                let commentRecordId = records.indices.contains(index)
                    ? records[index].recordId
                    : nil

                return .concat([
                    setProfile,
                    .just(.setRecords(records)),
                    commentRecordId.map { self.fetchComments(recordId: $0) } ?? .empty()
                ])
            } catch {
                return .concat([
                    setProfile,
                    .just(.setAlert(.failure(error as? NetworkError ?? .unknown)))
                ])
            }
        }
        .flatMap { $0 }

        return .concat([
            .just(.setInitialLoading(true)),
            fetch,
            .just(.setInitialLoading(false))
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
                createdTime: Date().toString(format: .custom("HH:mm")),
                isMine: true
            )
        )
    }

    /// 댓글을 먼저 목록에서 숨기고, 삭제에 실패하면 다시 보여줍니다.
    func deleteComment(commentId: Int, recordId: Int) -> Observable<Mutation> {
        let groupId = currentState.groupId

        let delete = asyncObservable { [weak self] () -> Observable<Mutation>? in
            guard let self else { return nil }

            do {
                try await self.chatUseCase.deleteComment(
                    groupId: groupId,
                    recordId: recordId,
                    commentId: commentId
                )
                return .just(.removeComment(commentId: commentId, recordId: recordId))
            } catch {
                return .from([
                    .setCommentDeleting(commentId: commentId, isDeleting: false),
                    .setAlert(.failure(error as? NetworkError ?? .unknown))
                ])
            }
        }
        .flatMap { $0 }

        return .concat([
            .just(.setCommentDeleting(commentId: commentId, isDeleting: true)),
            delete
        ])
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
