import ComposableArchitecture
import CommonDomain
import CoreAnalyticsInterface
import CoreAuthInterface
import CoreModyImageInterface
import UIKit
import XCTest
@testable import Splash

@MainActor
final class SplashFeatureTests: XCTestCase {
    func testRecommendUpdateFlagShowsDismissibleUpdatePopup() async {
        let store = makeStore(remoteConfigBools: [.recommendUpdate: true])
        store.exhaustivity = .off

        await store.send(.checkRecommendUpdate)
        await store.receive(\.showAlert)

        XCTAssertEqual(store.state.alertCase, .recommendUpdate(image: nil))
    }

    func testRecommendUpdateFlagOffContinuesToNotice() async {
        let store = makeStore(remoteConfigBools: [.recommendUpdate: false])
        store.exhaustivity = .off

        await store.send(.checkRecommendUpdate)
        await store.receive(\.checkNotice)
    }

    func testScrimTapOnRecommendUpdateDismissesPopupAndContinuesToNotice() async {
        var state = SplashFeature.State()
        state.alertCase = .recommendUpdate(image: nil)
        let store = makeStore(initialState: state)
        store.exhaustivity = .off

        await store.send(.alertAction(.scrimTapped))
        await store.receive(\.alertAction.dismiss)
        await store.receive(\.checkNotice)
        await store.finish()
    }

    func testScrimTapOnMinimumSupportedVersionKeepsPopup() async {
        var state = SplashFeature.State()
        state.alertCase = .minimumSupportedVersion
        let store = makeStore(initialState: state)

        // 지원 종료 팝업은 바깥 배경을 눌러도 아무 동작이 없어야 합니다.
        await store.send(.alertAction(.scrimTapped))
    }
}

private extension SplashFeatureTests {
    func makeStore(
        initialState: SplashFeature.State = SplashFeature.State(),
        remoteConfigBools: [RemoteConfigKeys: Bool] = [:]
    ) -> TestStoreOf<SplashFeature> {
        let repository = SplashFeatureRepositoryStub(remoteConfigBools: remoteConfigBools)

        return TestStore(initialState: initialState) {
            SplashFeature(
                splashUseCase: SplashUseCase(splashRepository: repository),
                authUseCase: AuthUseCaseStub(),
                analyticsUseCase: AnalyticsUseCaseStub(),
                imageLoader: RemoteImageLoaderStub(),
                router: { _ in }
            )
        }
    }
}

private struct StubError: Error {}

private struct SplashFeatureRepositoryStub: SplashRepositoryProtocol {
    let remoteConfigBools: [RemoteConfigKeys: Bool]

    func getHealthCheck() async throws -> Bool { true }
    func fetchAndActivate() async {}
    func getRemoteConfigBool(for key: RemoteConfigKeys) -> Bool { remoteConfigBools[key] ?? false }
    func getRemoteConfigString(for key: RemoteConfigKeys) -> String { "" }
    func getNoticePopupInfo() -> NoticePopupInfo? { nil }
    func hasSeenNotice(id: String) -> Bool { false }
    func markNoticeAsSeen(id: String) {}
    func getStoredAuthSession() -> AuthSession? { nil }
}

private struct AuthUseCaseStub: AuthUseCaseProtocol {
    func signIn(loginType: SocialLoginType, accessToken: String) async throws -> AuthSession {
        throw StubError()
    }

    func getUserInfo(needUpdateKeyChain: Bool) async throws -> UserInfo {
        throw StubError()
    }

    func logout() async throws {}
    func deleteAccount() async throws {}
    func getSocialLoginType() -> SocialLoginType? { nil }
}

private struct AnalyticsUseCaseStub: AnalyticsUseCaseProtocol {
    func setUserID(_ userID: String) {}
    func setUserNickname(_ nickname: String) {}
    func reset() {}
    func log(_ event: AmplitudeLogEvent) {}
    func log(_ event: GoogleAnalyticsEvent) {}
    func viewDidLoad(screenName: String) {}
}

private final class RemoteImageLoaderStub: RemoteImageLoading, @unchecked Sendable {
    func cachedImage(for request: RemoteImageRequest) -> UIImage? { nil }

    func loadImage(with request: RemoteImageRequest) async throws -> UIImage {
        throw StubError()
    }
}
