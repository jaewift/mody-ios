//
//  MainCoordinator+.swift
//  Main
//
//  Created by 김동준 on 7/6/26.
//

import ModyGroupInterface

@MainActor
extension MainCoordinator {
    func showGroupParticipate() {
        showModyGroup(entrySource: .feed, initialScreen: .participate)
    }

    func showGroupCreate(needBackButton: Bool) {
        showModyGroup(
            entrySource: .feed,
            initialScreen: .create(needBackButton: needBackButton)
        )
    }

    func showModyGroup(
        entryPoint: ModyGroupEntryPoint = .main,
        entrySource: ModyGroupEntrySource,
        initialScreen: ModyGroupInitialScreen
    ) {
        let viewController = modyGroupBuilder.makeModyGroupViewController(
            entryPoint: entryPoint,
            entrySource: entrySource,
            showSignUpDoneContents: false,
            initialScreen: initialScreen,
            router: self,
            outputHandler: self
        )

        navigationController.pushViewController(viewController, animated: true)
    }
}
