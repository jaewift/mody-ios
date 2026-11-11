//
//  FeedChatRecordCarouselView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreModyImageInterface
import SnapKit
import UIKit

/// 같은 날짜에 올라온 피드 사진을 좌우로 넘겨보는 영역입니다.
final class FeedChatRecordCarouselView: UIView {
    static let height: CGFloat = cardHeight + 16 + 8 + 20
    /// 피드 목록 카드(`FeedRecordCardCell`)와 같은 높이입니다.
    private static let cardHeight: CGFloat = 200

    var onPageChange: ((Int) -> Void)?

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    private let pageIndicatorView = FeedChatPageIndicatorView()
    private var cards: [FeedRecordCardContentViewState] = []
    private var currentPage = 0
    private var imageLoader: RemoteImageLoading?

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
        let itemSize = CGSize(width: bounds.width, height: Self.cardHeight)
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              itemSize.width > 0,
              layout.itemSize != itemSize else {
            return
        }

        layout.itemSize = itemSize
        layout.invalidateLayout()
        scrollToCurrentPage()
    }

    func configure(
        cards: [FeedRecordCardContentViewState],
        currentPage: Int,
        imageLoader: RemoteImageLoading
    ) {
        self.imageLoader = imageLoader
        let shouldScroll = self.currentPage != currentPage || self.cards.isEmpty

        if self.cards != cards {
            self.cards = cards
            collectionView.reloadData()
        }

        self.currentPage = currentPage
        pageIndicatorView.configure(numberOfPages: cards.count, currentPage: currentPage)

        if shouldScroll {
            collectionView.layoutIfNeeded()
            scrollToCurrentPage()
        }
    }
}

private extension FeedChatRecordCarouselView {
    func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            FeedChatRecordPageCell.self,
            forCellWithReuseIdentifier: FeedChatRecordPageCell.reuseIdentifier
        )
    }

    func setupLayout() {
        addSubview(collectionView)
        addSubview(pageIndicatorView)

        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Self.cardHeight)
        }

        pageIndicatorView.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(8)
        }
    }

    func scrollToCurrentPage() {
        guard cards.indices.contains(currentPage),
              collectionView.bounds.width > 0 else {
            return
        }

        collectionView.setContentOffset(
            CGPoint(x: CGFloat(currentPage) * collectionView.bounds.width, y: 0),
            animated: false
        )
    }
}

extension FeedChatRecordCarouselView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        cards.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeedChatRecordPageCell.reuseIdentifier,
            for: indexPath
        ) as? FeedChatRecordPageCell,
              let imageLoader else {
            return UICollectionViewCell()
        }

        cell.configure(cards[indexPath.item], imageLoader: imageLoader)
        return cell
    }

    /// 손가락을 떼는 시점에 도착할 페이지가 정해지므로, 감속을 기다리지 않고 바로 반영합니다.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard scrollView.bounds.width > 0 else { return }

        let page = Int((targetContentOffset.pointee.x / scrollView.bounds.width).rounded())
        guard page != currentPage, cards.indices.contains(page) else { return }

        currentPage = page
        pageIndicatorView.configure(numberOfPages: cards.count, currentPage: page, animated: true)
        onPageChange?(page)
    }
}
