//
//  FeedChatRecordPageCell.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreModyImageInterface
import SnapKit
import UIKit

final class FeedChatRecordPageCell: UICollectionViewCell {
    static let reuseIdentifier = "FeedChatRecordPageCell"

    private let cardView = FeedRecordCardContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.prepareForReuse()
    }

    func configure(
        _ viewState: FeedRecordCardContentViewState,
        imageLoader: RemoteImageLoading
    ) {
        cardView.configure(viewState, imageLoader: imageLoader)
    }
}

private extension FeedChatRecordPageCell {
    func setupLayout() {
        contentView.addSubview(cardView)

        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }
}
