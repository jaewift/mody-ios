//
//  FeedChatPageIndicatorView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import SnapKit
import UIKit

/// 선택된 페이지는 노란 캡슐, 나머지는 회색 점으로 표시합니다.
final class FeedChatPageIndicatorView: UIView {
    private enum Metric {
        static let dotSize: CGFloat = 6
        static let selectedWidth: CGFloat = 16
    }

    private let stackView = UIStackView()
    private var dotViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(numberOfPages: Int, currentPage: Int) {
        if dotViews.count != numberOfPages {
            rebuildDots(count: numberOfPages)
        }

        isHidden = numberOfPages <= 1

        for (index, dotView) in dotViews.enumerated() {
            let isSelected = index == currentPage
            dotView.backgroundColor = isSelected ? .main : .gray2
            dotView.snp.updateConstraints {
                $0.width.equalTo(isSelected ? Metric.selectedWidth : Metric.dotSize)
            }
        }
    }
}

private extension FeedChatPageIndicatorView {
    func setupUI() {
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
    }

    func setupLayout() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
    }

    func rebuildDots(count: Int) {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews = (0..<count).map { _ in
            let dotView = UIView()
            dotView.layer.cornerRadius = Metric.dotSize / 2
            dotView.snp.makeConstraints {
                $0.width.equalTo(Metric.dotSize)
                $0.height.equalTo(Metric.dotSize)
            }
            return dotView
        }
        dotViews.forEach { stackView.addArrangedSubview($0) }
    }
}
