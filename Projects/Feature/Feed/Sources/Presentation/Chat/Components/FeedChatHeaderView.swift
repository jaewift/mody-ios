//
//  FeedChatHeaderView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreModyImageInterface
import DesignSystem
import SnapKit
import UIKit

final class FeedChatHeaderView: UIView {
    let backButton = UIButton(type: .custom)
    let moreButton = UIButton(type: .custom)

    private let profileImageView = FeedRecordCardImageView()
    private let nicknameLabel = MUILabel(style: .b6, color: .gray9, alignment: .left)
    private let meChipView = UIView()
    private let meLabel = MUILabel(text: "나", style: .c4, color: .gray8)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        _ viewState: FeedChatHeaderViewState?,
        imageLoader: RemoteImageLoading
    ) {
        let profileImageRequest = FeedImageURLResolver.resolve(viewState?.profileImageUrl).map {
            RemoteImageRequest(
                url: $0,
                variantIdentifier: "feed-profile",
                maximumPixelSize: 96
            )
        }
        profileImageView.configure(
            request: profileImageRequest,
            cornerRadius: 16,
            fallbackImage: .icModyAvatarSmileLight,
            imageLoader: imageLoader
        )
        nicknameLabel.text = viewState?.nickname
        meChipView.isHidden = viewState?.isMine != true
        moreButton.isHidden = viewState == nil
    }
}

private extension FeedChatHeaderView {
    func setupUI() {
        backgroundColor = .systemWhite

        backButton.setImage(.icLeftArrow.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .gray8

        moreButton.setImage(.icMore.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .gray6
        moreButton.isHidden = true

        meChipView.backgroundColor = .main3
        meChipView.layer.cornerRadius = 11
        meChipView.isHidden = true
    }

    func setupLayout() {
        addSubview(backButton)
        addSubview(profileImageView)
        addSubview(nicknameLabel)
        addSubview(meChipView)
        meChipView.addSubview(meLabel)
        addSubview(moreButton)

        snp.makeConstraints {
            $0.height.equalTo(48)
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        profileImageView.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        meChipView.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(6)
            $0.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }

        meLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        moreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
    }
}
