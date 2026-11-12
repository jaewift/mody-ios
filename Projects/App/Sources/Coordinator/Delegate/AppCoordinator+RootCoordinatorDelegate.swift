//
//  AppCoordinator+RootCoordinatorDelegate.swift
//  Mody
//
//  Created by 김동준 on 6/25/26
//

import Root
import UIKit

@MainActor
extension AppCoordinator: RootCoordinatorDelegate {
    func didFinishAuthentication(_ coordinator: RootCoordinator) {
        showMain(animated: true)
        (UIApplication.shared.delegate as? AppDelegate)?.registerCurrentFCMToken()
    }
}
