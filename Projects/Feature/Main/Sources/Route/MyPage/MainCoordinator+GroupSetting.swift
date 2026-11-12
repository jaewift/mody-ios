//
//  MainCoordinator+GroupSetting.swift
//  Main
//
//  Created by 김동준 on 7/17/26
//

import ModyGroupInterface
import MyPageInterface

@MainActor
extension MainCoordinator: MyPageGroupSettingsRouter {
    public func route(from route: MyPageGroupSettingsRoute) {
        switch route {
        case .back:
            navigationController.popViewController(animated: true)
        case .routeToGroupParticipate:
            showModyGroup(
                entryPoint: .groupSettings,
                entrySource: .rejoin,
                initialScreen: .participate
            )
        }
    }
}
