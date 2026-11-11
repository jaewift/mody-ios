//
//  FeedChatView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import SnapKit
import UIKit

final class FeedChatView: UIView {
    let headerView = FeedChatHeaderView()
    let menuView = FeedRecordMenuView()
    let carouselView = FeedChatRecordCarouselView()
    let commentTableView = UITableView(frame: .zero, style: .plain)
    let emojiBarView = FeedChatEmojiBarView()
    let messageInputView = FeedChatInputView()

    private let carouselContainerView = UIView()
    private let bottomStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // tableHeaderView는 Auto Layout으로 높이가 정해지지 않아 너비가 바뀔 때 직접 맞춥니다.
        guard carouselContainerView.frame.width != commentTableView.bounds.width else { return }

        carouselContainerView.frame = CGRect(
            x: 0,
            y: 0,
            width: commentTableView.bounds.width,
            height: FeedChatRecordCarouselView.height + 8
        )
        commentTableView.tableHeaderView = carouselContainerView
    }
}

private extension FeedChatView {
    func setupUI() {
        backgroundColor = .systemWhite

        menuView.isHidden = true

        commentTableView.backgroundColor = .systemWhite
        commentTableView.separatorStyle = .none
        commentTableView.keyboardDismissMode = .interactive
        commentTableView.rowHeight = UITableView.automaticDimension
        commentTableView.estimatedRowHeight = 80
        commentTableView.contentInset.bottom = 8
        commentTableView.register(
            FeedChatCommentCell.self,
            forCellReuseIdentifier: FeedChatCommentCell.reuseIdentifier
        )

        bottomStackView.axis = .vertical
        bottomStackView.spacing = 12
        bottomStackView.backgroundColor = .systemWhite
        bottomStackView.isLayoutMarginsRelativeArrangement = true
        bottomStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 0,
            bottom: 8,
            trailing: 0
        )
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(commentTableView)
        addSubview(bottomStackView)
        addSubview(menuView)
        carouselContainerView.addSubview(carouselView)

        bottomStackView.addArrangedSubview(emojiBarView)
        bottomStackView.addArrangedSubview(messageInputView)

        headerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }

        menuView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(-4)
            $0.trailing.equalToSuperview().inset(24)
            $0.width.equalTo(88)
        }

        commentTableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomStackView.snp.top)
        }

        carouselView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(FeedChatRecordCarouselView.height)
        }

        bottomStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(keyboardLayoutGuide.snp.top)
        }
    }
}
