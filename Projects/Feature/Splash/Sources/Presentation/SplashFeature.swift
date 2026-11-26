//
//  SplashFeature.swift
//  Splash
//
//  Created by 김동준 on 6/25/26
//

import ComposableArchitecture
import SplashInterface
import CommonDomain
import CoreAnalyticsInterface
import CoreAuthInterface
import CoreModyImageInterface
import Foundation
import Base
import ModyLogger
import UIKit

@Reducer
public struct SplashFeature {
    /// 스플래시가 일러스트 로딩 때문에 오래 멈추지 않도록 하는 최대 대기 시간입니다.
    static let popupImageTimeout: Duration = .seconds(3)
    static let popupImageVariantIdentifier = "splash-popup-illustration"
    static let popupImageScale: CGFloat = 3

    private let splashUseCase: SplashUseCase
    private let authUseCase: AuthUseCaseProtocol
    private let analyticsUseCase: AnalyticsUseCaseProtocol
    private let imageLoader: RemoteImageLoading
    private let router: @MainActor (SplashRoute) -> Void

    public init(
        splashUseCase: SplashUseCase,
        authUseCase: AuthUseCaseProtocol,
        analyticsUseCase: AnalyticsUseCaseProtocol,
        imageLoader: RemoteImageLoading,
        router: @escaping @MainActor (SplashRoute) -> Void
    ) {
        self.splashUseCase = splashUseCase
        self.authUseCase = authUseCase
        self.analyticsUseCase = analyticsUseCase
        self.imageLoader = imageLoader
        self.router = router
    }

    @ObservableState
    public struct State: Equatable {
        public enum AlertCase: Equatable {
            case error(NetworkError)
            /// 바깥 배경을 눌러 닫을 수 있는 권장 업데이트 팝업입니다.
            case recommendUpdate(image: UIImage?)
            case minimumSupportedVersion
            case notice(NoticePopupInfo, image: UIImage?)
        }

        public init() {
            self.currentAppVersion = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? ""
        }
        
        var isLoading = true
        let currentAppVersion: String
        var appStoreURLString = ""
        var alertCase: AlertCase?
        var alertState = AlertFeature.State(dismissOnScrimTap: false)
    }
    
    public enum Action {
        case onAppear
        case serverHealthChecked(Bool)
        case userInfoFetched(UserInfo)
        case userInfoFetchFailed
        case setUpRemoteConfig
        case checkMinimumSupportedVersion
        case checkRecommendUpdate
        case checkNotice
        case alertAction(AlertFeature.Action)
        case showAlert(State.AlertCase)
        case noticeConfirmButtonTapped
        case healthCheck
    }
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.alertState, action: \.alertAction) {
            AlertFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.setUpRemoteConfig)
                }
            case .setUpRemoteConfig:
                return .run { send in
                    await splashUseCase.fetchAndActivate()
                    await send(.checkMinimumSupportedVersion)
                }
            case .checkMinimumSupportedVersion:
                let targetVersion = splashUseCase.getRemoteConfigString(for: .minimumSupportedVersion)
                
                let needsMinimumVersionUpdate = splashUseCase.needsMinimumVersionUpdate(
                    currentVersion: state.currentAppVersion,
                    targetVersion: targetVersion
                )

                if needsMinimumVersionUpdate {
                    state.appStoreURLString = splashUseCase.getRemoteConfigString(for: .appStoreURL)
                    return .send(.showAlert(.minimumSupportedVersion))
                }

                return .send(.checkRecommendUpdate)
            case .checkRecommendUpdate:
                // 한 번만 보기 없이 플래그가 켜져 있는 동안 실행할 때마다 노출합니다.
                guard splashUseCase.getRemoteConfigBool(for: .recommendUpdate) else {
                    return .send(.checkNotice)
                }

                state.appStoreURLString = splashUseCase.getRemoteConfigString(for: .appStoreURL)
                return showRecommendUpdateAlert()
            case .checkNotice:
                guard let notice = splashUseCase.getNoticeToShow() else {
                    return .send(.healthCheck)
                }

                guard let imageURL = notice.validImageURL else {
                    return .send(.showAlert(.notice(notice, image: nil)))
                }

                // 팝업이 뜬 뒤 이미지가 늦게 채워지지 않도록 미리 받아 둔 뒤 노출합니다.
                return .run { send in
                    let image = await loadPopupImage(from: imageURL)
                    await send(.showAlert(.notice(notice, image: image)))
                }
            case .alertAction(.scrimTapped):
                // 권장 업데이트만 바깥 배경으로 닫을 수 있고, 닫으면 다음 단계(공지 확인)로 이어갑니다.
                guard case .recommendUpdate = state.alertCase else {
                    return .none
                }

                return .run { send in
                    await send(.alertAction(.dismiss))
                    await send(.checkNotice)
                }
            case .alertAction:
                return .none
            case let .showAlert(alertCase):
                state.isLoading = false
                state.alertCase = alertCase
                return .send(.alertAction(.present))
            case .noticeConfirmButtonTapped:
                guard case let .notice(notice, _) = state.alertCase,
                      notice.skipPossible == true else {
                    return .none
                }

                splashUseCase.markNoticeAsSeen(notice)

                return .run { send in
                    await send(.alertAction(.dismiss))
                    await send(.healthCheck)
                }
            case .healthCheck:
                state.isLoading = true
                return .run { send in
                    await send(getHealthCheck())
                }
            case .serverHealthChecked(let isStable):
                if !isStable {
                    return .send(.showAlert(.error(.unknown)))
                }
                
                return .run { send in
                    await send(getUserInfo())
                }
            case .userInfoFetched(let userInfo):
                state.isLoading = false
                let destination = makeNavigationDestination(from: userInfo)
                let loginType = splashUseCase.getAuthSession()?.socialLoginType

                return .run { [router] _ in
                    analyticsUseCase.setUserID(String(userInfo.memberId))
                    analyticsUseCase.setUserNickname(userInfo.nickname)
                    analyticsUseCase.log(SplashAnalyticsEvent.loginSucceeded(method: loginType))
                    await router(destination)
                }
            case .userInfoFetchFailed:
                state.isLoading = false
                return .run { [router] _ in
                    await router(.routeToSignIn)
                }
            }
        }
    }
}

private extension SplashFeature {
    func makeNavigationDestination(from userInfo: UserInfo) -> SplashRoute {
        guard userInfo.personalInfoCompleted else {
            return .routeToOnBoarding
        }

        guard !userInfo.mainAccessible else {
            return .routeToMain
        }

        return .routeToModyGroup(showSignUpDoneContents: !userInfo.groupOnboardingCompleted)
    }

    func getHealthCheck() async -> Action {
        do {
            let isStable = try await splashUseCase.getHealthCheck()
            return .serverHealthChecked(isStable)
        } catch {
            return .showAlert(.error(error as? NetworkError ?? .unknown))
        }
    }

    /// 권장 업데이트 팝업을 띄웁니다. 일러스트 URL이 있으면 이미지를 미리 받아 둔 뒤 노출합니다.
    func showRecommendUpdateAlert() -> Effect<Action> {
        guard let imageURL = splashUseCase.getUpdatePopupImageURL() else {
            return .send(.showAlert(.recommendUpdate(image: nil)))
        }

        return .run { send in
            let image = await loadPopupImage(from: imageURL)
            await send(.showAlert(.recommendUpdate(image: image)))
        }
    }

    /// 팝업 일러스트를 받아옵니다. 실패하거나 제한 시간을 넘기면 이미지 없이 팝업을 띄우도록 `nil`을 반환합니다.
    func loadPopupImage(from url: URL) async -> UIImage? {
        let request = RemoteImageRequest(
            url: url,
            variantIdentifier: Self.popupImageVariantIdentifier,
            maximumPixelSize: Int(IllustratedPopupView.illustrationSize * Self.popupImageScale)
        )

        return await withTaskGroup(of: UIImage?.self) { [imageLoader] group in
            group.addTask {
                do {
                    return try await imageLoader.loadImage(with: request)
                } catch {
                    ModyLogger.debug("Popup image load failed: \(error)")
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(for: Self.popupImageTimeout)
                return nil
            }

            let firstResult = await group.next() ?? nil
            group.cancelAll()
            return firstResult
        }
    }

    func getUserInfo() async -> Action {
        do {
            let userInfo = try await authUseCase.getUserInfo(needUpdateKeyChain: true)
            return .userInfoFetched(userInfo)
        } catch {
            return .userInfoFetchFailed
        }
    }
}
