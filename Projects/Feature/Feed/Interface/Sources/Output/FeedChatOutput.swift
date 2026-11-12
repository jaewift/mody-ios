//
//  FeedChatOutput.swift
//  FeedInterface
//
//  Created by Jaewift on 11/11/26.
//

public enum FeedChatOutput: Equatable {
    case recordDeleted
}

@MainActor
public protocol FeedChatOutputHandler: AnyObject {
    func handle(output: FeedChatOutput)
}
