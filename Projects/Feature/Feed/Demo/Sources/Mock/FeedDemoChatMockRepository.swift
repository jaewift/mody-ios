//
//  FeedDemoChatMockRepository.swift
//  FeedDemo
//
//  Created by Jaewift on 11/11/26.
//

import Feed
import Foundation

actor FeedDemoChatMockRepository: FeedChatRepositoryProtocol {
    private let feedRepository: FeedRepositoryProtocol
    private var commentsByRecordId: [Int: [FeedComment]] = [:]
    private var nextCommentId = 1

    init(feedRepository: FeedRepositoryProtocol) {
        self.feedRepository = feedRepository
    }

    func getRecordDetail(
        groupId: Int,
        recordId: Int,
        cursor: Int?,
        size: Int
    ) async throws -> FeedRecordDetailPage {
        let page = try await feedRepository.getRecords(
            groupId: groupId,
            date: Self.todayText(),
            cursor: nil,
            size: size
        )
        let records = page.records.map {
            FeedRecordDetail(
                recordId: $0.recordId,
                recordType: $0.recordType,
                nickname: $0.nickname,
                profileImageUrl: $0.profileImageUrl,
                recordedTime: $0.recordedTime,
                menu: $0.menu,
                exerciseDurationMinutes: $0.exerciseDurationMinutes,
                exerciseName: $0.exerciseName,
                imageUrl: $0.imageUrl,
                imageCropRegion: $0.imageCropRegion,
                isMine: $0.memberId == Self.myMemberId
            )
        }

        return FeedRecordDetailPage(
            records: records,
            currentIndex: records.firstIndex { $0.recordId == recordId } ?? 0,
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
            createdTime: Self.currentTimeText()
        )
        nextCommentId += 1
        commentsByRecordId[recordId, default: Self.defaultComments].append(comment)
    }
}

private extension FeedDemoChatMockRepository {
    /// `FeedDemoAuthUseCase`가 내려주는 내 memberId와 같은 값입니다.
    static let myMemberId = 4_537_058_591_744

    static func todayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

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
