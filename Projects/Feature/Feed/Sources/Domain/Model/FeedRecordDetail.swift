//
//  FeedRecordDetail.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

/// 채팅 화면 상단에서 좌우로 넘겨보는 피드 한 장입니다.
public struct FeedRecordDetail: Equatable {
    public let recordId: Int
    public let recordType: FeedRecordKind
    public let nickname: String
    public let profileImageUrl: String?
    public let recordedTime: String
    public let menu: String
    public let exerciseDurationMinutes: Int
    public let exerciseName: String
    public let imageUrl: String
    public let imageCropRegion: FeedImageCropRegion?
    public let isMine: Bool

    public init(
        recordId: Int,
        recordType: FeedRecordKind,
        nickname: String,
        profileImageUrl: String?,
        recordedTime: String,
        menu: String,
        exerciseDurationMinutes: Int,
        exerciseName: String,
        imageUrl: String,
        imageCropRegion: FeedImageCropRegion?,
        isMine: Bool
    ) {
        self.recordId = recordId
        self.recordType = recordType
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.recordedTime = recordedTime
        self.menu = menu
        self.exerciseDurationMinutes = exerciseDurationMinutes
        self.exerciseName = exerciseName
        self.imageUrl = imageUrl
        self.imageCropRegion = imageCropRegion
        self.isMine = isMine
    }
}

extension FeedRecordDetail {
    init(record: FeedRecord, myMemberId: Int?) {
        self.init(
            recordId: record.recordId,
            recordType: record.recordType,
            nickname: record.nickname,
            profileImageUrl: record.profileImageUrl,
            recordedTime: record.recordedTime,
            menu: record.menu,
            exerciseDurationMinutes: record.exerciseDurationMinutes,
            exerciseName: record.exerciseName,
            imageUrl: record.imageUrl,
            imageCropRegion: record.imageCropRegion,
            isMine: record.memberId == myMemberId
        )
    }
}
