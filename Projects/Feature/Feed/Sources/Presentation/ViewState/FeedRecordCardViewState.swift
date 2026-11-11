//
//  FeedRecordCardViewState.swift
//  Feed
//
//  Created by 김동준 on 7/21/26
//

struct FeedRecordCardViewState: Equatable {
    let recordId: Int
    let nickname: String
    let profileImageUrl: String?
    let streakText: String
    let isStreakChipHidden: Bool
    let isMine: Bool
    let showsMoreButton: Bool
    let menus: [FeedRecordMenu]
    let content: FeedRecordCardContentViewState

    init(
        record: FeedRecord,
        myMemberId: Int?
    ) {
        let isMine = record.memberId == myMemberId

        recordId = record.recordId
        nickname = record.nickname
        profileImageUrl = record.profileImageUrl
        streakText = "\(record.recordingStreakDays)일차"
        isStreakChipHidden = record.recordingStreakDays <= 0
        self.isMine = isMine
        showsMoreButton = true
        menus = isMine ? [.delete] : [.report]
        content = FeedRecordCardContentViewState(
            recordType: record.recordType,
            imageUrl: record.imageUrl,
            imageCropRegion: record.imageCropRegion,
            recordedTime: record.recordedTime,
            menu: record.menu,
            exerciseDurationMinutes: record.exerciseDurationMinutes,
            exerciseName: record.exerciseName
        )
    }
}

struct FeedRecordCardContentViewState: Equatable {
    let imageUrl: String
    let imageCropRegion: FeedImageCropRegion?
    let firstInfoTitle: String
    let firstInfoValue: String
    let secondInfoTitle: String
    let secondInfoValue: String

    init(
        recordType: FeedRecordKind,
        imageUrl: String,
        imageCropRegion: FeedImageCropRegion?,
        recordedTime: String,
        menu: String,
        exerciseDurationMinutes: Int,
        exerciseName: String
    ) {
        self.imageUrl = imageUrl
        self.imageCropRegion = imageCropRegion

        switch recordType {
        case .meal:
            firstInfoTitle = "식사 시간"
            firstInfoValue = recordedTime
            secondInfoTitle = "메뉴"
            secondInfoValue = menu
        case .exercise:
            firstInfoTitle = "운동 시간"
            firstInfoValue = "\(exerciseDurationMinutes)분"
            secondInfoTitle = "운동종류"
            secondInfoValue = exerciseName
        }
    }
}

struct FeedListViewState: Equatable {
    let records: [FeedRecordCardViewState]
    let isInitialLoading: Bool
    let hasNextPage: Bool
    let isEmpty: Bool
}
