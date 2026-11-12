//
//  FeedChatViewController.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import Base
import CoreModyImageInterface
import DesignSystem
import ReactorKit
import RxCocoa
import RxSwift
import SwiftUI
import UIKit

public final class FeedChatViewController: UIViewController, ReactorKit.View {
    public var disposeBag = DisposeBag()

    private let chatView = FeedChatView()
    private let imageLoader: RemoteImageLoading
    private var comments: [FeedChatCommentViewState] = []

    var alertHostingController: UIHostingController<MAlertView>?
    var loadingHostingController: UIHostingController<AnyView>?

    private lazy var menuDismissTapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(didTapOutsideMenu)
    )

    public init(
        reactor: FeedChatReactor,
        imageLoader: RemoteImageLoading
    ) {
        self.imageLoader = imageLoader
        defer { self.reactor = reactor }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = chatView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureCommentTableView()
        addHostedView(FeedChatCommentEmptyView(), to: chatView.commentEmptyContainerView)
        configureMenuDismissGesture()
        configureLoadingView()
        reactor?.action.onNext(.viewDidLoad)
    }

    public func bind(reactor: FeedChatReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}

private extension FeedChatViewController {
    func bindAction(reactor: FeedChatReactor) {
        chatView.headerView.backButton.rx.tap
            .map { FeedChatReactor.Action.didTapBackButton }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        chatView.headerView.moreButton.rx.tap
            .bind(with: self) { owner, _ in
                guard owner.chatView.menuView.hasMenus else { return }
                owner.chatView.menuView.isHidden.toggle()
            }
            .disposed(by: disposeBag)

        chatView.menuView.onSelect = { [weak self, weak reactor] menu in
            self?.chatView.menuView.isHidden = true
            reactor?.action.onNext(.didTapRecordMenu(menu))
        }

        chatView.carouselView.onPageChange = { [weak self, weak reactor] page in
            self?.chatView.menuView.isHidden = true
            reactor?.action.onNext(.didChangePage(page))
        }

        chatView.emojiBarView.onSelect = { [weak reactor] emoji in
            reactor?.action.onNext(.didTapEmoji(emoji))
        }

        chatView.messageInputView.textField.rx.text.orEmpty
            .skip(1)
            .distinctUntilChanged()
            .map { FeedChatReactor.Action.didChangeCommentText($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        chatView.messageInputView.onSend = { [weak reactor] in
            reactor?.action.onNext(.didTapSendComment)
        }
    }

    func bindState(reactor: FeedChatReactor) {
        reactor.state
            .observe(on: MainScheduler.instance)
            .map { $0.currentRecord.map(FeedChatHeaderViewState.init(record:)) }
            .distinctUntilChanged()
            .bind(with: self) { owner, viewState in
                owner.chatView.headerView.configure(viewState, imageLoader: owner.imageLoader)
                owner.chatView.menuView.configure(menus: viewState?.menus ?? [])
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map { FeedChatCarouselViewState(records: $0.records, currentPage: $0.currentPageIndex) }
            .distinctUntilChanged()
            .bind(with: self) { owner, viewState in
                owner.chatView.carouselView.configure(
                    cards: viewState.cards,
                    currentPage: viewState.currentPage,
                    imageLoader: owner.imageLoader
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map { $0.displayedComments.map(FeedChatCommentViewState.init(comment:)) }
            .distinctUntilChanged()
            .bind(with: self) { owner, comments in
                owner.updateComments(comments)
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .compactMap { $0.currentRecord?.recordId }
            .distinctUntilChanged()
            .skip(1)
            .bind(with: self) { owner, _ in
                // 다른 피드로 넘기면 그 피드의 댓글을 처음부터 보여줍니다.
                let tableView = owner.chatView.commentTableView
                tableView.setContentOffset(
                    CGPoint(x: 0, y: -tableView.adjustedContentInset.top),
                    animated: false
                )
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map(\.isCommentEmpty)
            .distinctUntilChanged()
            .bind(with: self) { owner, isEmpty in
                owner.chatView.commentEmptyContainerView.isHidden = !isEmpty
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map(\.commentText)
            .distinctUntilChanged()
            .bind(with: self) { owner, text in
                let textField = owner.chatView.messageInputView.textField
                guard textField.text != text else { return }
                textField.text = text
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map(\.canSendComment)
            .distinctUntilChanged()
            .bind(with: self) { owner, canSend in
                owner.chatView.messageInputView.setSendEnabled(canSend)
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map { $0.isInitialLoading || $0.isRecordMenuLoading }
            .distinctUntilChanged()
            .bind(with: self) { owner, isLoading in
                owner.setLoadingVisible(isLoading)
            }
            .disposed(by: disposeBag)

        reactor.state
            .observe(on: MainScheduler.instance)
            .map(\.alert)
            .distinctUntilChanged()
            .bind(with: self) { owner, alert in
                owner.setAlert(alert)
            }
            .disposed(by: disposeBag)
    }

    func configureCommentTableView() {
        chatView.commentTableView.dataSource = self
    }

    func configureMenuDismissGesture() {
        menuDismissTapGestureRecognizer.cancelsTouchesInView = false
        menuDismissTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(menuDismissTapGestureRecognizer)
    }

    func updateComments(_ newComments: [FeedChatCommentViewState]) {
        let previousCount = comments.count
        comments = newComments
        chatView.commentTableView.reloadData()

        // 방금 보낸 내 댓글이 추가된 경우에만 마지막 댓글이 보이도록 이동합니다.
        guard newComments.count > previousCount,
              newComments.last?.isPending == true else {
            return
        }

        chatView.commentTableView.scrollToRow(
            at: IndexPath(row: newComments.count - 1, section: 0),
            at: .bottom,
            animated: true
        )
    }

    @objc func didTapOutsideMenu() {
        chatView.menuView.isHidden = true
        view.endEditing(true)
    }
}

extension FeedChatViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FeedChatCommentCell.reuseIdentifier,
            for: indexPath
        ) as? FeedChatCommentCell else {
            return UITableViewCell()
        }

        cell.configure(comments[indexPath.row], imageLoader: imageLoader)
        return cell
    }
}

extension FeedChatViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer === menuDismissTapGestureRecognizer,
              let touchedView = touch.view else {
            return true
        }

        // 메뉴·입력 영역을 누를 때는 메뉴를 닫거나 키보드를 내리지 않습니다.
        guard !touch.isInKeyboardDismissExcludedView else { return false }

        let menuViews: [UIView] = [chatView.menuView, chatView.headerView.moreButton]
        return !menuViews.contains { touchedView.isDescendant(of: $0) }
    }
}
