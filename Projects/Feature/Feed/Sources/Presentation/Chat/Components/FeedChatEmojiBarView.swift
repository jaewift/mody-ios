//
//  FeedChatEmojiBarView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import SnapKit
import UIKit

/// iOS 기본 이모지로 구성된 빠른 응원 버튼 목록입니다.
final class FeedChatEmojiBarView: UIView {
    private static let emojis = ["👏🏻", "🏅", "🔥", "💛", "🏃"]

    var onSelect: ((String) -> Void)?

    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension FeedChatEmojiBarView {
    func setupUI() {
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center

        Self.emojis.forEach { emoji in
            stackView.addArrangedSubview(makeEmojiButton(emoji))
        }
    }

    func setupLayout() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(36)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }

    func makeEmojiButton(_ emoji: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        configuration.attributedTitle = AttributedString(
            emoji,
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24)])
        )

        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = emoji
        button.addAction(
            UIAction { [weak self] _ in
                self?.onSelect?(emoji)
            },
            for: .touchUpInside
        )
        button.snp.makeConstraints {
            $0.size.equalTo(36)
        }
        return button
    }
}
