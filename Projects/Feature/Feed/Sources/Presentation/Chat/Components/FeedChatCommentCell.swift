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
    private let timeLabel = MUILabel(style: .c4, color: .gray5, alignment: .left)

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
        contentLabel.text = viewState.content
        timeLabel.text = viewState.createdTime
    }
}

private extension FeedChatCommentCell {
    func setupUI() {
        backgroundColor = .systemWhite
        selectionStyle = .none

        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    func setupLayout() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(contentLabel)
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

        bubbleView.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(6)
            $0.leading.equalTo(profileImageView)
            $0.bottom.equalToSuperview().inset(8)
        }

        contentLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview().inset(14)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(bubbleView.snp.trailing).offset(6)
            $0.trailing.lessThanOrEqualToSuperview().inset(24)
            $0.bottom.equalTo(bubbleView)
        }
    }
}
