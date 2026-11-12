//
//  FeedRecordCardCell.swift
//  Feed
//
//  Created by 김동준 on 7/21/26
//

import CoreModyImageInterface
import UIKit
import DesignSystem
import SnapKit

final class FeedRecordCardCell: UICollectionViewCell {
    static let reuseIdentifier = "FeedRecordCardCell"
    static let contentHeight: CGFloat = 244

    var onMenuSelect: ((FeedRecordMenu) -> Void)?
    var onRecordTap: (() -> Void)?

    private let contentStackView = UIStackView()
    private let headerView = UIView()
    private let profileImageView = FeedRecordCardImageView()
    private let nicknameLabel = MUILabel(style: .b6, color: .gray10, alignment: .left)
    private let streakChipView = UIView()
    private let streakLabel = MUILabel(style: .c2, color: .gray10)
    private let streakIconImageView = UIImageView(image: .icFireFill)
    private let moreButton = UIButton(type: .custom)
    private let menuView = FeedRecordMenuView()
    private let cardView = FeedRecordCardContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        cardView.prepareForReuse()
        onMenuSelect = nil
        onRecordTap = nil
        dismissMenu()
    }

    func configure(
        _ viewState: FeedRecordCardViewState,
        imageLoader: RemoteImageLoading
    ) {
        dismissMenu()

        let profileImageRequest = FeedImageURLResolver.resolve(viewState.profileImageUrl).map {
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
        nicknameLabel.text = viewState.nickname
        streakLabel.text = viewState.streakText
        streakChipView.isHidden = viewState.isStreakChipHidden
        moreButton.isHidden = !viewState.showsMoreButton
        menuView.configure(menus: viewState.menus)
        cardView.configure(viewState.content, imageLoader: imageLoader)
    }

    func dismissMenu() {
        menuView.isHidden = true
    }

    func containsMenuInteraction(_ view: UIView) -> Bool {
        view === moreButton
            || view.isDescendant(of: moreButton)
            || view === menuView
            || view.isDescendant(of: menuView)
    }
}

private extension FeedRecordCardCell {
    func setupUI() {
        contentView.backgroundColor = .systemWhite

        contentStackView.axis = .vertical
        contentStackView.spacing = 12

        streakChipView.backgroundColor = .gray1
        streakChipView.layer.cornerRadius = 14
        streakChipView.layer.borderColor = UIColor.gray3.cgColor
        streakChipView.layer.borderWidth = 0.4

        streakIconImageView.contentMode = .scaleAspectFit

        moreButton.setImage(UIImage.icMore.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = .gray6
        moreButton.addAction(
            UIAction { [weak self] _ in
                self?.toggleMenu()
            },
            for: .touchUpInside
        )

        menuView.isHidden = true
        menuView.onSelect = { [weak self] menu in
            self?.dismissMenu()
            self?.onMenuSelect?(menu)
        }

        cardView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapCard))
        )
    }

    func setupLayout() {
        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(cardView)

        headerView.addSubview(profileImageView)
        headerView.addSubview(nicknameLabel)
        headerView.addSubview(streakChipView)
        streakChipView.addSubview(streakLabel)
        streakChipView.addSubview(streakIconImageView)
        headerView.addSubview(moreButton)

        contentView.addSubview(menuView)

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(32)
        }

        profileImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
        }

        streakChipView.snp.makeConstraints {
            $0.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(profileImageView)
            $0.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-8)
        }

        streakLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalToSuperview().offset(8)
        }

        streakIconImageView.snp.makeConstraints {
            $0.leading.equalTo(streakLabel.snp.trailing).offset(2)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        moreButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        menuView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(88)
        }

        cardView.snp.makeConstraints {
            $0.height.equalTo(200)
        }
    }

    @objc func didTapCard() {
        onRecordTap?()
    }

    func toggleMenu() {
        guard menuView.hasMenus else { return }
        menuView.isHidden.toggle()
    }
}
