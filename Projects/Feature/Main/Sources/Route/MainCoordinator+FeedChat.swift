//
//  MainCoordinator+FeedChat.swift
//  Main
//
//  Created by Jaewift on 11/11/26.
//

import FeedInterface
import UIKit

extension MainCoordinator: FeedChatRouter {
    public func route(from route: FeedChatRoute) {
        switch route {
        case .back:
            navigationController.popViewController(animated: true)
        }
    }
}

extension MainCoordinator: FeedChatOutputHandler {
    public func handle(output: FeedChatOutput) {
        switch output {
        case .recordDeleted:
            navigationController.popViewController(animated: true)
            feedInputHandler?.handle(input: .recordDeleted)
        }
    }
}
