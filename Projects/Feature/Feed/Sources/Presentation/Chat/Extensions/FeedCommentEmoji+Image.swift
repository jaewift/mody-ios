//
//  FeedCommentEmoji+Image.swift
//  Feed
//
//  Created by Jaewift on 11/16/26.
//

import DesignSystem
import UIKit

extension FeedCommentEmoji {
    var image: UIImage {
        switch self {
        case .clap: .imgEmojiClap
        case .medal: .imgEmojiMedal
        case .fire: .imgEmojiFire
        case .heart: .imgEmojiHeart
        case .run: .imgEmojiRun
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .clap: "박수"
        case .medal: "메달"
        case .fire: "불꽃"
        case .heart: "하트"
        case .run: "달리기"
        }
    }
}
