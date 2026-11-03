//
//  ImageUploadUseCase.swift
//  CoreModyImage
//
//  Created by 김동준 on 7/25/26.
//

import CoreModyImageInterface
import Foundation

public struct ImageUploadUseCase: ImageUploadUseCaseProtocol {
    private let repository: ImageUploadRepositoryProtocol

    public init(repository: ImageUploadRepositoryProtocol) {
        self.repository = repository
    }

    public func uploadImage(
        fileURL: URL,
        fileName: String,
        domain: ImageUploadDomain
    ) async throws -> String {
        let maximumPixelSize = switch domain {
        case .record: 2048
        case .profile: 640
        }
        // 업로드 파일은 항상 JPEG로 다시 인코딩되므로 확장자를 맞춥니다.
        let baseName = (fileName as NSString).deletingPathExtension
        let uploadFileName = "\(baseName).jpg"

        let presignedUpload = try await repository.postPresignedURL(
            domain: domain,
            fileName: uploadFileName
        )
        try await repository.putImage(
            fileURL: fileURL,
            to: presignedUpload.url,
            maximumPixelSize: maximumPixelSize
        )

        return presignedUpload.imageKey
    }
}
