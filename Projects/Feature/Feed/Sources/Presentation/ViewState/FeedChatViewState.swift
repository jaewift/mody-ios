//
//  FeedChatViewState.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

struct FeedChatHeaderViewState: Equatable {
    let nickname: String
    let profileImageUrl: String?
    let isMine: Bool
    let menus: [FeedRecordMenu]

    init(record: FeedRecordDetail) {
        nickname = record.nickname
        profileImageUrl = record.profileImageUrl
        isMine = record.isMine
        menus = record.isMine ? [.delete] : [.report]
    }
}

struct FeedChatCarouselViewState: Equatable {
    let cards: [FeedRecordCardContentViewState]
    let currentPage: Int

    init(records: [FeedRecordDetail], currentPage: Int) {
        cards = records.map {
            FeedRecordCardContentViewState(
                recordType: $0.recordType,
                imageUrl: $0.imageUrl,
                imageCropRegion: $0.imageCropRegion,
                recordedTime: $0.recordedTime,
                menu: $0.menu,
                exerciseDurationMinutes: $0.exerciseDurationMinutes,
                exerciseName: $0.exerciseName
            )
        }
        self.currentPage = currentPage
    }
}

struct FeedChatCommentViewState: Equatable {
    let commentId: Int
    let nickname: String
    let profileImageUrl: String?
    let content: String
    let createdTime: String
    let isMine: Bool
    /// 서버 저장 전 임시 댓글(음수 id)입니다.
    let isPending: Bool

    init(comment: FeedComment) {
        commentId = comment.commentId
        isPending = comment.commentId < 0
        nickname = comment.nickname
        profileImageUrl = comment.profileImageUrl
        content = comment.content
        createdTime = comment.createdTime
        isMine = comment.isMine
    }
}
