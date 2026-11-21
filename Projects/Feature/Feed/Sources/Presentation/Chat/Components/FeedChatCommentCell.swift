//
//  FeedChatCommentCell.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreModyImageInterface
import DesignSystem
import SnapKit
import UIKit

final class FeedChatCommentCell: UITableViewCell {
    static let reuseIdentifier = "FeedChatCommentCell"

    /// 말풍선을 길게 눌렀을 때 말풍선 뷰를 전달합니다.
    var onLongPress: ((UIView) -> Void)?

    private let profileImageView = FeedRecordCardImageView()
    private let nicknameLabel = MUILabel(style: .c4, color: .gray7, alignment: .left)
    private let bubbleView = FeedChatBubbleView()
    private let contentLabel = MUILabel(
        style: .c2,
        color: .gray10,
        numberOfLines: 0,
        alignment: .left,
        lineBreakMode: .byCharWrapping
    )
    private let emojiImageView = UIImageView()
    private let timeLabel = MUILabel(style: .c4, color: .gray5, alignment: .left)
    private var isEmojiLayout: Bool?
    private var isMineLayout: Bool?
    private lazy var longPressGestureRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(didLongPressBubble)
    )

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.prepareForReuse()
        onLongPress = nil
    }

    func configure(
        _ viewState: FeedChatCommentViewState,
        imageLoader: RemoteImageLoading
    ) {
        let profileImageRequest = FeedImageURLResolver.resolve(viewState.profileImageUrl).map {
            RemoteImageRequest(
                url: $0,
                variantIdentifier: "feed-profile",
                maximumPixelSize: 96
            )
        }
        profileImageView.configure(
            request: profileImageRequest,
            cornerRadius: 14,
            fallbackImage: .icModyAvatarSmileLight,
            imageLoader: imageLoader
        )
        nicknameLabel.text = viewState.nickname
        contentLabel.attributedText = FeedCommentContentFormatter.attributedString(
            from: viewState.contentSegments,
            attributes: ModyTypography.c2.token.attributes(
                color: .gray10,
                alignment: .left,
                lineBreakMode: .byCharWrapping
            ),
            emojiSize: Metric.inlineEmojiSize
        )
        contentLabel.accessibilityLabel = FeedCommentContentFormatter.accessibilityText(
            from: viewState.contentSegments
        )
        emojiImageView.image = viewState.emoji?.image
        updateContentLayout(isEmoji: viewState.emoji != nil)
        timeLabel.text = viewState.createdTime
        updateLayout(isMine: viewState.isMine)
        // 서버에 저장된 댓글만 길게 눌러 삭제(내 댓글)하거나 신고(다른 사람 댓글)할 수 있습니다.
        longPressGestureRecognizer.isEnabled = !viewState.isPending
    }
}

private extension FeedChatCommentCell {
    enum Metric {
        static let emojiSize: CGFloat = 40
        /// 글과 함께 쓴 이모지 크기입니다.
        static let inlineEmojiSize: CGFloat = 24
    }

    func setupUI() {
        backgroundColor = .systemWhite
        selectionStyle = .none

        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        bubbleView.addGestureRecognizer(longPressGestureRecognizer)
    }

    func setupLayout() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(contentLabel)
        bubbleView.addSubview(emojiImageView)
        contentView.addSubview(timeLabel)

        profileImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(24)
            $0.size.equalTo(28)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualToSuperview().inset(24)
            $0.centerY.equalTo(profileImageView)
        }

        emojiImageView.contentMode = .scaleAspectFit

        updateLayout(isMine: false)
        updateContentLayout(isEmoji: false)
    }

    /// 이모지 댓글은 말풍선 배경 없이 이모지 이미지만 크게 보여줍니다.
    func updateContentLayout(isEmoji: Bool) {
        guard isEmojiLayout != isEmoji else { return }
        isEmojiLayout = isEmoji

        bubbleView.showsBackground = !isEmoji
        contentLabel.isHidden = isEmoji
        emojiImageView.isHidden = !isEmoji

        if isEmoji {
            contentLabel.snp.removeConstraints()
            emojiImageView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
                $0.size.equalTo(Metric.emojiSize)
            }
        } else {
            emojiImageView.snp.removeConstraints()
            contentLabel.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview().inset(10)
                $0.leading.trailing.equalToSuperview().inset(14)
            }
        }
    }

    @objc func didLongPressBubble(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        onLongPress?(bubbleView)
    }

    /// 내 댓글은 프로필 없이 오른쪽에, 다른 사람 댓글은 프로필 아래 왼쪽에 배치합니다.
    func updateLayout(isMine: Bool) {
        guard isMineLayout != isMine else { return }
        isMineLayout = isMine

        profileImageView.isHidden = isMine
        nicknameLabel.isHidden = isMine
        bubbleView.isMine = isMine

        if isMine {
            bubbleView.snp.remakeConstraints {
                $0.top.equalToSuperview().offset(8)
                $0.trailing.equalToSuperview().inset(24)
                $0.bottom.equalToSuperview().inset(8)
            }

            timeLabel.snp.remakeConstraints {
                $0.trailing.equalTo(bubbleView.snp.leading).offset(-6)
                $0.leading.greaterThanOrEqualToSuperview().offset(24)
                $0.bottom.equalTo(bubbleView)
            }
        } else {
            bubbleView.snp.remakeConstraints {
                $0.top.equalTo(profileImageView.snp.bottom).offset(6)
                $0.leading.equalTo(profileImageView)
                $0.bottom.equalToSuperview().inset(8)
            }

            timeLabel.snp.remakeConstraints {
                $0.leading.equalTo(bubbleView.snp.trailing).offset(6)
                $0.trailing.lessThanOrEqualToSuperview().inset(24)
                $0.bottom.equalTo(bubbleView)
            }
        }
    }
}
