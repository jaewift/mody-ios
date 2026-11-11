//
//  FeedChatBubbleView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import DesignSystem
import UIKit

/// 프로필 쪽(왼쪽 위) 모서리만 살짝 둥글고 나머지는 크게 둥근 말풍선입니다.
final class FeedChatBubbleView: UIView {
    private enum Metric {
        static let tailCornerRadius: CGFloat = 4
        static let cornerRadius: CGFloat = 18
    }

    private let backgroundLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundLayer.fillColor = UIColor.gray1.cgColor
        layer.insertSublayer(backgroundLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        backgroundLayer.path = makePath(in: bounds).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundLayer.fillColor = UIColor.gray1.cgColor
    }
}

private extension FeedChatBubbleView {
    func makePath(in rect: CGRect) -> UIBezierPath {
        let tail = min(Metric.tailCornerRadius, rect.height / 2)
        let radius = min(Metric.cornerRadius, rect.height / 2, rect.width / 2)
        let path = UIBezierPath()

        path.move(to: CGPoint(x: rect.minX + tail, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tail))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + tail, y: rect.minY + tail),
            radius: tail,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.close()
        return path
    }
}
