//
//  FeedChatRoute.swift
//  FeedInterface
//
//  Created by Jaewift on 11/11/26.
//

public enum FeedChatRoute: Equatable {
    case back
}

@MainActor
public protocol FeedChatRouter: AnyObject {
    func route(from route: FeedChatRoute)
}
