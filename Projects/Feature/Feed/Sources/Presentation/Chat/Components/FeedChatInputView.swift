//
//  FeedChatInputView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import SnapKit
import UIKit

/// 글 사이에 이모지 이미지를 넣을 수 있도록 `UITextField` 대신 `UITextView`를 씁니다.
/// (`UITextField`는 `NSTextAttachment`를 지웁니다.)
final class FeedChatInputView: UIView, KeyboardDismissExcluding {
    private let textView = UITextView()
    private let sendButton = UIButton(type: .custom)

    var onSend: (() -> Void)?
    var onTextChange: ((String) -> Void)?

    /// 글 사이의 이모지 이미지를 `:mody-id:` 토큰으로 바꾼 입력 내용입니다.
    var content: String {
        FeedCommentContentFormatter.content(from: textView.attributedText ?? NSAttributedString())
    }

    private let containerView = UIView()
    private let placeholderLabel = MUILabel(
        text: "버디에게 응원 한마디를 남겨보세요!",
        style: .c2,
        color: .gray5,
        alignment: .left
    )
    private let stackView = UIStackView()
    private let textAttributes: [NSAttributedString.Key: Any] = {
        let font = ModyTypography.c2.token.uiFont
        // 이모지 이미지가 들어가도 줄 높이가 바뀌지 않도록 고정합니다.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = font.lineHeight
        paragraphStyle.maximumLineHeight = font.lineHeight
        return [
            .font: font,
            .foregroundColor: UIColor.gray10,
            .paragraphStyle: paragraphStyle
        ]
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 입력 내용의 이모지 토큰을 이미지로 바꿔 보여줍니다.
    func setContent(_ content: String) {
        textView.attributedText = FeedCommentContentFormatter.attributedString(
            from: FeedCommentContentParser.segments(from: content),
            attributes: textAttributes
        )
        // 이모지 뒤에 이어 쓰는 글자도 같은 글꼴로 입력되도록 합니다.
        textView.typingAttributes = textAttributes
        textView.scrollRangeToVisible(textView.selectedRange)
        updatePlaceholder()
    }

    func setSendEnabled(_ isEnabled: Bool) {
        sendButton.isEnabled = isEnabled
        sendButton.alpha = isEnabled ? 1 : 0.4
    }
}

private extension FeedChatInputView {
    enum Metric {
        static let height: CGFloat = 44
        static let horizontalInset: CGFloat = 16
    }

    func setupUI() {
        containerView.backgroundColor = .gray00
        containerView.layer.cornerRadius = Metric.height / 2
        containerView.layer.borderColor = UIColor.gray2.cgColor
        containerView.layer.borderWidth = 1

        let font = ModyTypography.c2.token.uiFont
        let verticalInset = max(0, (Metric.height - font.lineHeight) / 2)
        textView.backgroundColor = .clear
        textView.typingAttributes = textAttributes
        textView.tintColor = .gray10
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        textView.showsVerticalScrollIndicator = false
        textView.textContainerInset = UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self

        placeholderLabel.isUserInteractionEnabled = false

        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center

        sendButton.setImage(.icSend, for: .normal)
        sendButton.accessibilityLabel = "보내기"
        sendButton.isHidden = true
        sendButton.addAction(
            UIAction { [weak self] _ in
                self?.send()
            },
            for: .touchUpInside
        )
    }

    func setupLayout() {
        addSubview(stackView)
        stackView.addArrangedSubview(containerView)
        stackView.addArrangedSubview(sendButton)
        containerView.addSubview(textView)
        containerView.addSubview(placeholderLabel)

        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(Metric.height)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        containerView.snp.makeConstraints {
            $0.height.equalTo(Metric.height)
        }

        sendButton.snp.makeConstraints {
            $0.size.equalTo(Metric.height)
        }

        textView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Metric.horizontalInset)
            $0.top.bottom.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(textView)
            $0.centerY.equalToSuperview()
        }
    }

    /// 전송 후 키보드를 내립니다.
    func send() {
        onSend?()
        textView.resignFirstResponder()
    }

    func updatePlaceholder() {
        placeholderLabel.isHidden = textView.hasText
    }

    // 키보드가 올라와 입력 중일 때만 전송 버튼을 보여줍니다.
    func setSendButtonVisible(_ isVisible: Bool) {
        guard sendButton.isHidden == isVisible else { return }

        UIView.animate(withDuration: 0.2) {
            self.sendButton.isHidden = !isVisible
            self.stackView.layoutIfNeeded()
        }
    }
}

extension FeedChatInputView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        // 키보드의 보내기 키는 줄바꿈 대신 댓글을 보냅니다.
        guard text != "\n" else {
            send()
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        onTextChange?(content)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        setSendButtonVisible(true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        setSendButtonVisible(false)
    }
}
