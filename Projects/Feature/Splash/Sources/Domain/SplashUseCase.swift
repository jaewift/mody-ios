//
//  SplashUseCase.swift
//  Splash
//
//  Created by 김동준 on 7/1/26
//

import CommonDomain
import Foundation

public struct SplashUseCase {
    private let splashRepository: SplashRepositoryProtocol

    public init(splashRepository: SplashRepositoryProtocol) {
        self.splashRepository = splashRepository
    }

    public func getHealthCheck() async throws -> Bool {
        try await splashRepository.getHealthCheck()
    }

    public func fetchAndActivate() async {
        await splashRepository.fetchAndActivate()
    }

    public func getRemoteConfigBool(for key: RemoteConfigKeys) -> Bool {
        splashRepository.getRemoteConfigBool(for: key)
    }

    public func getRemoteConfigString(for key: RemoteConfigKeys) -> String {
        splashRepository.getRemoteConfigString(for: key)
    }

    /// 노출해야 할 공지만 반환합니다. 비어 있거나 이미 확인한 일회성 공지는 `nil`입니다.
    public func getNoticeToShow() -> NoticePopupInfo? {
        guard let notice = splashRepository.getNoticePopupInfo(),
              !notice.isEmpty else {
            return nil
        }

        if let oneTimeID = notice.oneTimeID,
           splashRepository.hasSeenNotice(id: oneTimeID) {
            return nil
        }

        return notice
    }

    public func markNoticeAsSeen(_ notice: NoticePopupInfo) {
        guard let oneTimeID = notice.oneTimeID else { return }
        splashRepository.markNoticeAsSeen(id: oneTimeID)
    }

    public func getAuthSession() -> AuthSession? {
        splashRepository.getStoredAuthSession()
    }
}

public extension SplashUseCase {
    func needsMinimumVersionUpdate(
        currentVersion: String?,
        targetVersion: String
    ) -> Bool {
        guard let currentVersion,
              let currentComponents = versionComponents(from: currentVersion),
              let targetComponents = versionComponents(from: targetVersion) else {
            return false
        }

        for (current, target) in zip(currentComponents, targetComponents) {
            guard current != target else { continue }
            return current < target
        }

        return false
    }
}

private extension SplashUseCase {
    func versionComponents(from version: String) -> [Int]? {
        let components = version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".", omittingEmptySubsequences: false)

        guard components.count == 3 else { return nil }

        let numbers = components.compactMap { Int($0) }
        guard numbers.count == components.count,
              numbers.allSatisfy({ $0 >= 0 }) else {
            return nil
        }

        return numbers
    }
}
