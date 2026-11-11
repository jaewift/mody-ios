//
//  FeedRecordDetail.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

public struct FeedRecordDetailPage: Equatable {
    public let records: [FeedRecordDetail]
    public let currentIndex: Int
    public let nextCursor: Int?
    public let hasNext: Bool

    public init(
        records: [FeedRecordDetail],
        currentIndex: Int,
        nextCursor: Int?,
        hasNext: Bool
    ) {
        self.records = records
        self.currentIndex = currentIndex
        self.nextCursor = nextCursor
        self.hasNext = hasNext
    }
}

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
