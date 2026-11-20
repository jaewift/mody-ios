//
//  FeedChatEmojiBarView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import SnapKit
import UIKit

/// 응원 이모지 버튼 목록입니다. 입력 중인 글이 없으면 바로 보내고, 있으면 글 끝에 붙입니다.
final class FeedChatEmojiBarView: UIView, KeyboardDismissExcluding {
    var onSelect: ((FeedCommentEmoji) -> Void)?

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

        FeedCommentEmoji.allCases.forEach { emoji in
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

    func makeEmojiButton(_ emoji: FeedCommentEmoji) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        configuration.image = emoji.image

        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = emoji.accessibilityLabel
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
