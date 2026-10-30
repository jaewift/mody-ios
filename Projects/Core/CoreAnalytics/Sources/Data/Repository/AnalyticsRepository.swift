//
//  AnalyticsRepository.swift
//  CoreAnalytics
//
//  Created by 김동준 on 8/17/26.
//

import CoreAnalyticsInterface

public struct AnalyticsRepository: AnalyticsRepositoryProtocol {
    private let amplitudeService: AmplitudeService
    private let firebaseAnalyticsService: FirebaseAnalyticsService

    public init(
        amplitudeService: AmplitudeService,
        firebaseAnalyticsService: FirebaseAnalyticsService
    ) {
        self.amplitudeService = amplitudeService
        self.firebaseAnalyticsService = firebaseAnalyticsService
    }

    public func setUserID(_ userID: String) {
        amplitudeService.setUserID(userID)
    }

    public func setUserNickname(_ nickname: String) {
        amplitudeService.setUserNickname(nickname)
    }

    public func reset() {
        amplitudeService.reset()
    }

    public func log(_ event: AmplitudeLogEvent) {
        amplitudeService.log(event)
    }

    public func log(_ event: GoogleAnalyticsEvent) {
        firebaseAnalyticsService.log(event)
    }

    public func viewDidLoad(screenName: String) {
        amplitudeService.viewDidLoad(screenName: screenName)
    }
}
