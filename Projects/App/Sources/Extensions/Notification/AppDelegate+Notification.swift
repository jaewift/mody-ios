//
//  AppDelegate+Notification.swift
//  Mody
//
//  Created by 김동준 on 7/18/26.
//

import FirebaseMessaging
import ModyLogger
import UIKit

extension AppDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        ModyLogger.debug("[APNs] device token: \(token)")
        Messaging.messaging().apnsToken = deviceToken
        resetFCMTokenIfNeeded()
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        ModyLogger.debug("[APNs] registration error: \(error)")
    }
}

extension AppDelegate {
    // 앱 이전 후 FCM에서 비활성화된 기존 토큰을 버리고 새 토큰을 발급받기 위한 1회성 플래그
    private static let fcmTokenResetKey = "didResetFCMTokenAfterAppTransfer"

    private var needsFCMTokenReset: Bool {
        !UserDefaults.standard.bool(forKey: Self.fcmTokenResetKey)
    }

    func resetFCMTokenIfNeeded() {
        guard needsFCMTokenReset else { return }

        Messaging.messaging().deleteToken { [weak self] error in
            if let error {
                ModyLogger.debug("[FCM] token delete error: \(error)")
                return
            }
            UserDefaults.standard.set(true, forKey: Self.fcmTokenResetKey)
            ModyLogger.debug("[FCM] token reset completed")
            self?.registerCurrentFCMToken()
        }
    }

    func registerCurrentFCMToken() {
        Messaging.messaging().token { [weak self] fcmToken, error in
            guard let fcmToken else {
                ModyLogger.debug("[FCM] token fetch error: \(String(describing: error))")
                return
            }
            self?.registerFCMToken(fcmToken)
        }
    }

    func registerFCMToken(_ fcmToken: String) {
        // 초기화 전에는 비활성화된 기존 토큰이 서버에 다시 등록되지 않도록 건너뜀
        guard !needsFCMTokenReset else { return }

        let deviceID = UIDevice.current.identifierForVendor?.uuidString

        Task { [notificationUseCase, deviceID] in
            _ = await notificationUseCase.pushFCMToken(
                fcmToken,
                deviceID: deviceID
            )
        }
    }
}
