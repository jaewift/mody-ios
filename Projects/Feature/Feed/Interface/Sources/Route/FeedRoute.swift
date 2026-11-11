//
//  FeedRoute.swift
//  FeedInterface
//
//  Created by 김동준 on 6/30/26
//

public enum FeedRoute: Equatable {
    case addGroup
    case routeToChallenge
    case routeToRecord(FeedRecordType)
    case routeToChat(groupId: Int, date: String, recordId: Int)
}

@MainActor
public protocol FeedRouter: AnyObject {
    func route(from route: FeedRoute)
}
