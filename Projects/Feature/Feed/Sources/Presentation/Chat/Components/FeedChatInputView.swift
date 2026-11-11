//
//  FeedChatInputView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import SnapKit
import UIKit

final class FeedChatInputView: UIView {
    let textField = UITextField()
    let sendButton = UIButton(type: .custom)

    var onSend: (() -> Void)?

    private let containerView = UIView()
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

    func setSendEnabled(_ isEnabled: Bool) {
        sendButton.isEnabled = isEnabled
        sendButton.alpha = isEnabled ? 1 : 0.4
    }
}

private extension FeedChatInputView {
    func setupUI() {
        containerView.backgroundColor = .gray00
        containerView.layer.cornerRadius = 22
        containerView.layer.borderColor = UIColor.gray2.cgColor
        containerView.layer.borderWidth = 1

        let typography = ModyTypography.c2.token
        textField.font = typography.uiFont
        textField.textColor = .gray10
        textField.tintColor = .gray10
        textField.returnKeyType = .send
        textField.enablesReturnKeyAutomatically = true
        textField.attributedPlaceholder = typography.attributedString(
            "버디에게 응원 한마디를 남겨보세요!",
            color: .gray5,
            alignment: .left
        )
        textField.addAction(
            UIAction { [weak self] _ in
                self?.onSend?()
            },
            for: .editingDidEndOnExit
        )
        // 키보드가 올라와 입력 중일 때만 전송 버튼을 보여줍니다.
        textField.addAction(
            UIAction { [weak self] _ in
                self?.setSendButtonVisible(true)
            },
            for: .editingDidBegin
        )
        textField.addAction(
            UIAction { [weak self] _ in
                self?.setSendButtonVisible(false)
            },
            for: .editingDidEnd
        )

        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center

        sendButton.setImage(.icSend, for: .normal)
        sendButton.accessibilityLabel = "보내기"
        sendButton.isHidden = true
        sendButton.addAction(
            UIAction { [weak self] _ in
                self?.onSend?()
            },
            for: .touchUpInside
        )
    }

    func setSendButtonVisible(_ isVisible: Bool) {
        guard sendButton.isHidden == isVisible else { return }

        UIView.animate(withDuration: 0.2) {
            self.sendButton.isHidden = !isVisible
            self.stackView.layoutIfNeeded()
        }
    }

    func setupLayout() {
        addSubview(stackView)
        stackView.addArrangedSubview(containerView)
        stackView.addArrangedSubview(sendButton)
        containerView.addSubview(textField)

        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(44)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        containerView.snp.makeConstraints {
            $0.height.equalTo(44)
        }

        sendButton.snp.makeConstraints {
            $0.size.equalTo(44)
        }

        textField.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }
    }
}
