//
//  FeedRecordDetailResponse.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import Foundation

struct FeedRecordDetailResponse: Decodable, Equatable {
    let currentIndex: Int?
    let records: [FeedRecordDetailItemResponse]?
    let nextCursor: Int?
    let hasNext: Bool?
}

struct FeedRecordDetailItemResponse: Decodable, Equatable {
    let recordId: Int?
    let recordType: String?
    let nickname: String?
    let profileImageUrl: String?
    let recordedTime: String?
    let menu: String?
    let exerciseDurationMinutes: Int?
    let exerciseName: String?
    let imageUrl: String?
    let imageCropRegion: FeedImageCropRegionResponse?
    let isMine: Bool?
}

extension FeedRecordDetailResponse {
    func toDomain() -> FeedRecordDetailPage {
        FeedRecordDetailPage(
            records: (records ?? []).compactMap { $0.toDomain() },
            currentIndex: currentIndex ?? 0,
            nextCursor: nextCursor,
            hasNext: hasNext ?? false
        )
    }
}

private extension FeedRecordDetailItemResponse {
    func toDomain() -> FeedRecordDetail? {
        guard let recordId,
              let imageUrl = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageUrl.isEmpty else {
            return nil
        }

        return FeedRecordDetail(
            recordId: recordId,
            recordType: FeedRecordKind(rawValue: recordType ?? "") ?? .meal,
            nickname: nickname ?? "",
            profileImageUrl: profileImageUrl,
            recordedTime: String((recordedTime ?? "").prefix(5)),
            menu: menu ?? "",
            exerciseDurationMinutes: exerciseDurationMinutes ?? 0,
            exerciseName: exerciseName ?? "",
            imageUrl: imageUrl,
            imageCropRegion: imageCropRegion?.toDomain(),
            isMine: isMine ?? false
        )
    }
}
