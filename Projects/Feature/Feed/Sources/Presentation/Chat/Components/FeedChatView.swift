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
    /// 내 댓글을 길게 눌렀을 때 말풍선 옆에 띄우는 메뉴입니다.
    let commentMenuView = FeedRecordMenuView()
    let carouselView = FeedChatRecordCarouselView()
    let commentTableView = UITableView(frame: .zero, style: .plain)
    /// 댓글이 없을 때 안내 화면을 올려두는 자리입니다.
    let commentEmptyContainerView = UIView()
    let emojiBarView = FeedChatEmojiBarView()
    let messageInputView = FeedChatInputView()

    private let bottomContainerView = UIView()
    private let bottomStackView = UIStackView()
    private var observations: [NSKeyValueObservation] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
        observeCommentScroll()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 말풍선 아래에 메뉴를 띄우고, 입력 영역에 가려지면 말풍선 위에 띄웁니다.
    func showCommentMenu(at bubbleView: UIView) {
        let bubbleFrame = bubbleView.convert(bubbleView.bounds, to: self)
        let menuSize = commentMenuView.intrinsicContentSize
        let spacing: CGFloat = 4
        let fitsBelow = bubbleFrame.maxY + spacing + menuSize.height <= bottomContainerView.frame.minY
        let top = fitsBelow
            ? bubbleFrame.maxY + spacing
            : bubbleFrame.minY - spacing - menuSize.height

        commentMenuView.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(top)
            $0.trailing.equalToSuperview().offset(bubbleFrame.maxX - bounds.width)
            $0.size.equalTo(menuSize)
        }
        commentMenuView.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 경계선 쪽으로만 그림자가 번지도록 해당 가장자리의 얇은 띠에만 그림자를 줍니다.
        carouselView.layer.shadowPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: carouselView.bounds.height - Metric.shadowBandHeight,
            width: carouselView.bounds.width,
            height: Metric.shadowBandHeight
        )).cgPath
        bottomContainerView.layer.shadowPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: bottomContainerView.bounds.width,
            height: Metric.shadowBandHeight
        )).cgPath
        updateScrollEdgeShadows()
    }
}

private extension FeedChatView {
    enum Metric {
        static let shadowBandHeight: CGFloat = 12
        static let shadowOpacity: Float = 0.08
    }

    func observeCommentScroll() {
        observations = [
            commentTableView.observe(\.contentOffset) { [weak self] _, _ in
                self?.updateScrollEdgeShadows()
            },
            commentTableView.observe(\.contentSize) { [weak self] _, _ in
                self?.updateScrollEdgeShadows()
            }
        ]
    }

    /// 댓글이 피드 영역 뒤로 넘어가면 위쪽 그림자를, 입력 영역 뒤에 더 남아 있으면 아래쪽 그림자를 보여줍니다.
    func updateScrollEdgeShadows() {
        let tableView = commentTableView
        let offsetY = tableView.contentOffset.y
        let hiddenAbove = offsetY > -tableView.adjustedContentInset.top + 1
        let visibleBottom = offsetY + tableView.bounds.height - tableView.adjustedContentInset.bottom
        let hiddenBelow = visibleBottom < tableView.contentSize.height - 1

        setShadow(on: carouselView, isVisible: hiddenAbove)
        setShadow(on: bottomContainerView, isVisible: hiddenBelow)
    }

    func setShadow(on view: UIView, isVisible: Bool) {
        let opacity = isVisible ? Metric.shadowOpacity : 0
        guard view.layer.shadowOpacity != opacity else { return }

        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = view.layer.presentation()?.shadowOpacity ?? view.layer.shadowOpacity
        animation.toValue = opacity
        animation.duration = 0.15
        view.layer.add(animation, forKey: "shadowOpacity")
        view.layer.shadowOpacity = opacity
    }

    func configureShadow(on view: UIView, offsetY: CGFloat) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: offsetY)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0
    }
}

private extension FeedChatView {
    func setupUI() {
        backgroundColor = .systemWhite

        menuView.isHidden = true
        commentMenuView.isHidden = true
        commentMenuView.configure(menus: [.delete])
        commentEmptyContainerView.isHidden = true

        commentTableView.backgroundColor = .systemWhite
        commentTableView.separatorStyle = .none
        commentTableView.keyboardDismissMode = .interactive
        commentTableView.rowHeight = UITableView.automaticDimension
        commentTableView.estimatedRowHeight = 80
        commentTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        commentTableView.register(
            FeedChatCommentCell.self,
            forCellReuseIdentifier: FeedChatCommentCell.reuseIdentifier
        )

        // 댓글 목록이 뒤로 지나가도록 피드 영역과 입력 영역은 배경을 칠하고 그림자를 준비합니다.
        carouselView.backgroundColor = .systemWhite
        bottomContainerView.backgroundColor = .systemWhite
        configureShadow(on: carouselView, offsetY: 4)
        configureShadow(on: bottomContainerView, offsetY: -4)

        bottomStackView.axis = .vertical
        bottomStackView.spacing = 12
        bottomStackView.isLayoutMarginsRelativeArrangement = true
        bottomStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 0,
            bottom: 8,
            trailing: 0
        )
    }

    func setupLayout() {
        // 그림자가 댓글 위에 그려지도록 피드 영역과 입력 영역을 목록보다 앞에 둡니다.
        addSubview(commentTableView)
        addSubview(commentEmptyContainerView)
        addSubview(headerView)
        addSubview(carouselView)
        addSubview(bottomContainerView)
        addSubview(commentMenuView)
        addSubview(menuView)
        bottomContainerView.addSubview(bottomStackView)

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

        carouselView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(FeedChatRecordCarouselView.height)
        }

        commentTableView.snp.makeConstraints {
            $0.top.equalTo(carouselView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomContainerView.snp.top)
        }

        commentEmptyContainerView.snp.makeConstraints {
            $0.top.equalTo(carouselView.snp.bottom)
            $0.leading.trailing.bottom.equalTo(commentTableView)
        }

        bottomContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(keyboardLayoutGuide.snp.top)
        }

        bottomStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
