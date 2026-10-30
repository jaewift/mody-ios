//
//  AppAssembly+CoreAnalytics.swift
//  Mody
//
//  Created by 김동준 on 8/17/26.
//

import CoreAnalytics
import CoreAnalyticsInterface
import Foundation
import Swinject

extension AppAssembly {
    func assembleCoreAnalytics(in container: Container) {
        container.register(AmplitudeService.self) { _ in
            AmplitudeService(apiKey: Bundle.main.object(forInfoDictionaryKey: "AMPLITUDE_API_KEY") as? String)
        }
        .inObjectScope(.container)

        container.register(FirebaseAnalyticsService.self) { _ in
            FirebaseAnalyticsService()
        }
        .inObjectScope(.container)

        container.register(AnalyticsRepositoryProtocol.self) { resolver in
            let amplitudeService: AmplitudeService = resolver.resolve()
            let firebaseAnalyticsService: FirebaseAnalyticsService = resolver.resolve()

            return AnalyticsRepository(
                amplitudeService: amplitudeService,
                firebaseAnalyticsService: firebaseAnalyticsService
            )
        }

        container.register(AnalyticsUseCaseProtocol.self) { resolver in
            let analyticsRepository: AnalyticsRepositoryProtocol = resolver.resolve()

            return AnalyticsUseCase(analyticsRepository: analyticsRepository)
        }
    }
}
