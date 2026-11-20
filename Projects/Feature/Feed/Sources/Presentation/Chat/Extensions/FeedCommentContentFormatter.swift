//
//  FeedCommentContentFormatter.swift
//  Feed
//
//  Created by Jaewift on 11/20/26.
//

import UIKit

/// 글 사이에 넣은 응원 이모지 이미지입니다. 보낼 때 다시 `:mody-id:` 토큰으로 바꿉니다.
final class FeedCommentEmojiAttachment: NSTextAttachment {
    let emoji: FeedCommentEmoji

    /// `size`가 없으면 글자 한 줄 높이만큼만 차지해 줄 높이가 커지지 않도록 합니다.
    init(emoji: FeedCommentEmoji, font: UIFont, size: CGFloat? = nil) {
        self.emoji = emoji
        super.init(data: nil, ofType: nil)
        image = emoji.image
        let size = size ?? font.lineHeight
        // 글자의 세로 가운데에 이모지 가운데를 맞춥니다.
        let y = (font.ascender + font.descender - size) / 2
        bounds = CGRect(x: 0, y: y, width: size, height: size)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum FeedCommentContentFormatter {
    /// 이모지 토큰을 이미지로 바꾼 문자열을 만듭니다.
    /// `emojiSize`를 주면 이모지를 그 크기로 그리고, 이모지가 들어갈 만큼 줄 높이를 늘립니다.
    static func attributedString(
        from segments: [FeedCommentContentSegment],
        attributes: [NSAttributedString.Key: Any],
        emojiSize: CGFloat? = nil
    ) -> NSAttributedString {
        let font = attributes[.font] as? UIFont ?? .systemFont(ofSize: UIFont.systemFontSize)
        let hasEmoji = segments.contains { if case .emoji = $0 { true } else { false } }
        let attributes = hasEmoji
            ? fittedAttributes(attributes, emojiSize: emojiSize, font: font)
            : attributes
        let result = NSMutableAttributedString()

        for segment in segments {
            switch segment {
            case let .text(text):
                result.append(NSAttributedString(string: text, attributes: attributes))
            case let .emoji(emoji):
                let attachment = NSMutableAttributedString(
                    attachment: FeedCommentEmojiAttachment(emoji: emoji, font: font, size: emojiSize)
                )
                // 줄 높이·정렬·기준선이 글자와 같도록 같은 속성을 씁니다.
                attachment.addAttributes(attributes, range: NSRange(location: 0, length: attachment.length))
                result.append(attachment)
            }
        }
        return result
    }

    /// 큰 이모지가 위아래 줄과 겹치지 않도록 줄 높이를 늘리고, 글자는 줄 가운데에 둡니다.
    private static func fittedAttributes(
        _ attributes: [NSAttributedString.Key: Any],
        emojiSize: CGFloat?,
        font: UIFont
    ) -> [NSAttributedString.Key: Any] {
        guard let emojiSize,
              let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle,
              paragraphStyle.maximumLineHeight < emojiSize + emojiLineSpacing else {
            return attributes
        }

        let lineHeight = emojiSize + emojiLineSpacing
        let fittedParagraphStyle = (paragraphStyle.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        fittedParagraphStyle.minimumLineHeight = lineHeight
        fittedParagraphStyle.maximumLineHeight = lineHeight

        var fittedAttributes = attributes
        fittedAttributes[.paragraphStyle] = fittedParagraphStyle
        fittedAttributes[.baselineOffset] = max(0, lineHeight - font.lineHeight) / 2
        return fittedAttributes
    }

    /// 큰 이모지 위아래로 두는 여백입니다.
    private static let emojiLineSpacing: CGFloat = 2

    /// 이미지로 바꿨던 이모지를 다시 `:mody-id:` 토큰으로 바꿔 서버에 보낼 내용을 만듭니다.
    static func content(from attributedText: NSAttributedString) -> String {
        var content = ""
        attributedText.enumerateAttributes(
            in: NSRange(location: 0, length: attributedText.length)
        ) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? FeedCommentEmojiAttachment {
                content += String(repeating: attachment.emoji.token, count: range.length)
            } else {
                content += attributedText.attributedSubstring(from: range).string
            }
        }
        return content
    }

    /// VoiceOver가 이모지 이미지를 이름으로 읽도록 합니다.
    static func accessibilityText(from segments: [FeedCommentContentSegment]) -> String {
        segments.map { segment in
            switch segment {
            case let .text(text): text
            case let .emoji(emoji): " \(emoji.accessibilityLabel) "
            }
        }
        .joined()
        .trimmingCharacters(in: .whitespaces)
    }
}
